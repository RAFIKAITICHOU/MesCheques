import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/merge_report.dart';
import '../providers/checks_provider.dart';
import '../providers/locale_provider.dart';
import '../services/merge_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'conflict_screen.dart';

class MergePreviewScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final MergeReport initialReport;

  const MergePreviewScreen({
    super.key,
    required this.data,
    required this.initialReport,
  });

  @override
  State<MergePreviewScreen> createState() => _MergePreviewScreenState();
}

class _MergePreviewScreenState extends State<MergePreviewScreen> {
  final MergeService _mergeService = MergeService();
  late MergeReport _report;
  bool _isProcessing = false;

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

  Future<void> _executeMerge() async {
    final l10n = AppLocalizations.of(context)!;
    if (_report.hasConflicts && !_report.isFullyResolved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.allConflictsMustBeResolved)),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await _mergeService.applyMerge(
        data: widget.data,
        resolvedConflicts: _report.conflicts,
      );

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
                const Icon(Icons.check_circle, color: AppColors.used, size: 24),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.mergeSuccessTitle)),
              ],
            ),
            content: Text(l10n.mergeSuccessDesc),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // pop dialog
                  navigator.pop(true); // pop preview screen
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
            title: const Text('Erreur de fusion'),
            content: Text('Impossible de finaliser la fusion : $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.understood),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();
    final isArabic = localeProvider.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mergePreviewTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            if (_isProcessing) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
            ],

            // Export date banner
            if (_report.fileCreatedAt != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.fileDate(
                          Formatters.formatDate(_report.fileCreatedAt, isArabic: isArabic),
                        ),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Counts Card
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildReportRow(
                      icon: Icons.add_circle_outline,
                      color: AppColors.used,
                      text: l10n.newChecks(_report.newChecksCount),
                    ),
                    const Divider(),
                    _buildReportRow(
                      icon: Icons.edit_outlined,
                      color: AppColors.primary,
                      text: l10n.updatedChecks(_report.updatedChecksCount),
                    ),
                    const Divider(),
                    _buildReportRow(
                      icon: Icons.check_circle_outline,
                      color: AppColors.textSecondary,
                      text: l10n.identicalChecks(_report.identicalChecksCount),
                    ),
                    const Divider(),
                    _buildReportRow(
                      icon: Icons.person_outline,
                      color: AppColors.inStock,
                      text: l10n.newPersons(_report.newPersonsCount),
                    ),
                    if (_report.purgedPropagatedCount > 0) ...[
                      const Divider(),
                      _buildReportRow(
                        icon: Icons.auto_delete_outlined,
                        color: AppColors.textMuted,
                        text: l10n.purgedSynced(_report.purgedPropagatedCount),
                      ),
                    ],
                    if (_report.hasConflicts) ...[
                      const Divider(),
                      _buildReportRow(
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.danger,
                        text: l10n.conflictsToResolve(_report.conflictsCount),
                        isBold: true,
                        trailing: ElevatedButton.icon(
                          onPressed: _resolveConflicts,
                          icon: const Icon(Icons.tune, size: 16),
                          label: Text(l10n.resolveConflictsBtn, style: const TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Comparison Totals Card
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.total,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.existingVersion,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_report.currentChecksTotal} chèques',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  Formatters.formatAmount(_report.currentAmountCents, isArabic: isArabic),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.incomingVersion,
                                  style: const TextStyle(fontSize: 11, color: AppColors.primary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_report.incomingChecksTotal} chèques',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                ),
                                Text(
                                  Formatters.formatAmount(_report.incomingAmountCents, isArabic: isArabic),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _executeMerge,
                    child: Text(l10n.mergeNow),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildReportRow({
    required IconData icon,
    required Color color,
    required String text,
    bool isBold = false,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
