import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/merge_report.dart';
import '../providers/checks_provider.dart';
import '../services/backup_service.dart';
import '../services/drive_service.dart';
import '../services/merge_service.dart';
import '../utils/constants.dart';
import 'conflict_screen.dart';

enum RestoreMode {
  merge,   // Fusionner (recommandé : rien n'est supprimé)
  replace, // Remplacer tout (avancé : efface les données du téléphone)
}

class RestorePreviewScreen extends StatefulWidget {
  final BackupRestoreBundle bundle;
  final MergeReport initialReport;
  final DriveService? driveService;

  const RestorePreviewScreen({
    super.key,
    required this.bundle,
    required this.initialReport,
    this.driveService,
  });

  @override
  State<RestorePreviewScreen> createState() => _RestorePreviewScreenState();
}

class _RestorePreviewScreenState extends State<RestorePreviewScreen> {
  late MergeReport _report;
  RestoreMode _selectedMode = RestoreMode.merge;
  bool _isProcessing = false;
  String? _processingStep;

  @override
  void initState() {
    super.initState();
    _report = widget.initialReport;
  }

  Future<void> _resolveConflicts() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ConflictScreen(conflicts: _report.conflicts),
      ),
    );
    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _executeRestore() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedMode == RestoreMode.merge && _report.hasConflicts && !_report.isFullyResolved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.allConflictsMustBeResolved)),
      );
      return;
    }

    if (_selectedMode == RestoreMode.replace) {
      // Double confirmation for Replace All mode
      final confirm1 = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 28),
              const SizedBox(width: 8),
              const Expanded(child: Text('Attention : Remplacement total')),
            ],
          ),
          content: const Text(
            'Cette opération va EFFACER toutes les données et images actuellement stockées sur ce téléphone pour les remplacer par celles de Google Drive.\n\nUne sauvegarde de secours locale sera automatiquement créée avant le remplacement.\n\nVoulez-vous continuer ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Oui, continuer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm1 != true) return;

      if (!mounted) return;
      final confirm2 = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmation définitive'),
          content: const Text('Êtes-vous absolument sûr ? Les chèques locaux non présents sur Drive seront supprimés.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Écraser et remplacer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm2 != true) return;
    }

    setState(() {
      _isProcessing = true;
      _processingStep = 'Création d\'une sauvegarde de sécurité locale...';
    });

    try {
      final driveSvc = widget.driveService ?? DriveService();
      final mergeSvc = MergeService();
      final backupSvc = BackupService();

      if (_selectedMode == RestoreMode.merge) {
        setState(() => _processingStep = 'Fusion des chèques et personnes...');
        await mergeSvc.applyMerge(
          data: widget.bundle.data,
          resolvedConflicts: _report.conflicts,
        );
      } else {
        setState(() => _processingStep = 'Remplacement complet des données...');
        await backupSvc.replaceDatabase(widget.bundle);
      }

      // Restore missing images from Drive if images folder is available
      final imagesList = (widget.bundle.data['check_images'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (imagesList.isNotEmpty) {
        setState(() => _processingStep = 'Récupération des photos depuis Google Drive...');
        await driveSvc.restoreMissingImagesFromDrive(imagesList);
      }

      if (mounted) {
        await context.read<ChecksProvider>().refreshAll();

        if (!mounted) return;
        final navigator = Navigator.of(context);
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.used, size: 26),
                const SizedBox(width: 8),
                const Expanded(child: Text('Restauration réussie')),
              ],
            ),
            content: Text(
              _selectedMode == RestoreMode.merge
                  ? 'Les données de Google Drive ont été fusionnées avec succès. Rien n\'a été perdu sur ce téléphone.'
                  : 'Toutes les données ont été restaurées avec succès depuis Google Drive.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  navigator.pop(true);
                },
                child: Text(l10n.understood),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Erreur de restauration'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingStep = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restauration depuis Drive'),
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 18),
                  Text(
                    _processingStep ?? 'Restauration en cours...',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Breakdown card
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.cloud_download, color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Aperçu de la restauration',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      'Comparaison avec les données locales',
                                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildMetricRow(
                            icon: Icons.add_circle,
                            color: AppColors.used,
                            count: _report.newChecksCount,
                            label: 'Chèque(s) à ajouter depuis Drive',
                          ),
                          const SizedBox(height: 10),
                          _buildMetricRow(
                            icon: Icons.edit,
                            color: AppColors.primary,
                            count: _report.updatedChecksCount,
                            label: 'Chèque(s) à mettre à jour (plus récents)',
                          ),
                          const SizedBox(height: 10),
                          _buildMetricRow(
                            icon: Icons.check_circle_outline,
                            color: AppColors.textSecondary,
                            count: _report.identicalChecksCount,
                            label: 'Chèque(s) déjà identiques',
                          ),
                          if (_report.hasConflicts) ...[
                            const SizedBox(height: 10),
                            _buildMetricRow(
                              icon: Icons.warning_amber_rounded,
                              color: AppColors.inStock,
                              count: _report.conflicts.length,
                              label: 'Conflit(s) à vérifier',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (_report.hasConflicts && _selectedMode == RestoreMode.merge) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.inStockBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.inStock.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning, color: AppColors.inStock, size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_report.conflicts.length} conflit(s) détecté(s)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.inStock),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Le même numéro de chèque existe sur le téléphone et sur Drive avec des informations différentes.',
                            style: TextStyle(fontSize: 12.5),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.inStock,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.rule, size: 18),
                            label: Text(
                              _report.isFullyResolved
                                  ? 'Modifier la résolution des conflits'
                                  : 'Résoudre les ${_report.unresolvedCount} conflit(s)',
                            ),
                            onPressed: _resolveConflicts,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Mode selection
                  const Text(
                    'Mode de restauration',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),

                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: RadioGroup<RestoreMode>(
                      groupValue: _selectedMode,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMode = val);
                      },
                      child: Column(
                        children: [
                          RadioListTile<RestoreMode>(
                            value: RestoreMode.merge,
                            activeColor: AppColors.primary,
                            title: const Text(
                              'Fusionner (recommandé)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                            ),
                            subtitle: const Text(
                              'Rien n\'est supprimé sur le téléphone. Les chèques présents seulement sur le téléphone sont conservés, ceux de Drive sont ajoutés.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                          const Divider(height: 1),
                          RadioListTile<RestoreMode>(
                            value: RestoreMode.replace,
                            activeColor: AppColors.danger,
                            title: const Text(
                              'Remplacer tout (avancé)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.danger),
                            ),
                            subtitle: const Text(
                              'Efface complètement la base locale et la remplace par la copie exacte de Drive. À utiliser si ce téléphone est vide ou corrompu.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Restore action button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedMode == RestoreMode.merge ? AppColors.primary : AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _executeRestore,
                    child: Text(
                      _selectedMode == RestoreMode.merge
                          ? 'Confirmer la fusion'
                          : 'Remplacer les données du téléphone',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Une sauvegarde de sécurité locale est automatiquement créée avant l\'opération.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricRow({
    required IconData icon,
    required Color color,
    required int count,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
