import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/app_meta_dao.dart';
import '../services/auto_backup_service.dart';
import '../services/drive_service.dart';
import '../services/merge_service.dart';
import '../utils/constants.dart';
import 'restore_preview_screen.dart';

class DriveSettingsScreen extends StatefulWidget {
  final DriveService? driveService;
  final AutoBackupService? autoBackupService;

  const DriveSettingsScreen({
    super.key,
    this.driveService,
    this.autoBackupService,
  });

  @override
  State<DriveSettingsScreen> createState() => _DriveSettingsScreenState();
}

class _DriveSettingsScreenState extends State<DriveSettingsScreen> {
  late final DriveService _driveService;
  late final AutoBackupService _autoBackupService;
  final AppMetaDao _appMetaDao = AppMetaDao();

  bool _isLoading = true;
  DriveAccountInfo? _accountInfo;
  bool _autoBackupEnabled = true;
  String _frequency = 'after_edit';
  bool _wifiOnly = false;
  int _keepVersions = 2;
  bool _includeImages = true;

  String? _lastBackupAt;
  int _lastChecksCount = 0;
  int _lastImagesCount = 0;
  int _driveUsedBytes = 0;
  String? _recoveryCode;

  @override
  void initState() {
    super.initState();
    _driveService = widget.driveService ?? DriveService();
    _autoBackupService = widget.autoBackupService ?? AutoBackupService.instance;
    _autoBackupService.addListener(_onAutoBackupChanged);
    _loadSettings();
  }

  @override
  void dispose() {
    _autoBackupService.removeListener(_onAutoBackupChanged);
    super.dispose();
  }

  void _onAutoBackupChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    _accountInfo = await _driveService.getCurrentUser();
    _autoBackupEnabled = await _appMetaDao.getBool('auto_backup_enabled', true);
    _frequency = await _appMetaDao.getValue('auto_backup_frequency') ?? 'after_edit';
    _wifiOnly = await _appMetaDao.getBool('auto_backup_wifi_only', false);
    _keepVersions = await _appMetaDao.getInt('auto_backup_keep_versions', 2);
    _includeImages = await _appMetaDao.getBool('auto_backup_include_images', true);

    _lastBackupAt = await _appMetaDao.getValue('last_backup_at');
    _lastChecksCount = await _appMetaDao.getInt('last_backup_checks_count', 0);
    _lastImagesCount = await _appMetaDao.getInt('last_backup_images_count', 0);
    _recoveryCode = await _driveService.getRecoveryCode();

    if (_accountInfo != null) {
      _driveUsedBytes = await _driveService.getDriveStorageUsageBytes();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignIn() async {
    try {
      final account = await _driveService.signIn();
      if (account != null) {
        // If password is not yet configured, prompt user to set it
        final hasPassword = await _driveService.hasMasterPassword();
        if (!hasPassword && mounted) {
          await _promptSetupMasterPassword();
        }
        await _loadSettings();
        await _autoBackupService.refreshStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connexion Google Drive échouée : $e')),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion Google Drive'),
        content: const Text(
          'Voulez-vous vraiment déconnecter votre compte Google Drive ?\nLes sauvegardes automatiques seront suspendues.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _driveService.signOut();
      await _loadSettings();
      await _autoBackupService.refreshStatus();
    }
  }

  Future<void> _promptSetupMasterPassword() async {
    final pwdController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.shield, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            const Expanded(child: Text('Mot de passe de sauvegarde')),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Créez un mot de passe pour chiffrer vos sauvegardes sur Google Drive. Ce mot de passe sera mémorisé de façon sécurisée sur cet appareil pour les sauvegardes automatiques.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.inStockBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⚠ Sans ce mot de passe, la sauvegarde Drive sera irrécupérable sur un autre appareil.',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.inStock),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: pwdController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe (8 caractères min)',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (val) {
                  if (val == null || val.length < 8) {
                    return 'Au moins 8 caractères requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon: Icon(Icons.lock_reset),
                ),
                validator: (val) {
                  if (val != pwdController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() == true) {
                await _driveService.saveMasterPassword(pwdController.text);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _showRecoveryCodeDialog();
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRecoveryCodeDialog() async {
    final code = await _driveService.getRecoveryCode();
    if (code == null || !mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clé de secours'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notez précieusement cette clé de secours sur un papier. Elle vous permettra de déverrouiller votre sauvegarde en cas d\'oubli du mot de passe :',
              style: TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      code,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Clé de secours copiée')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('J\'ai bien noté'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBackupNow({bool force = false}) async {
    try {
      final success = await _autoBackupService.triggerBackupNow(forceIfDrop: force);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sauvegarde Drive effectuée avec succès !')),
        );
        await _loadSettings();
      }
    } on DriveDropWarningException catch (e) {
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: AppColors.danger, size: 24),
              const SizedBox(width: 8),
              const Expanded(child: Text('Baisse importante de chèques')),
            ],
          ),
          content: Text(
            'Cette sauvegarde contient ${e.localCount} chèque(s), alors que celle de Drive en contient ${e.remoteCount}.\n\nVoulez-vous quand même remplacer la version Drive ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remplacer quand même', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _handleBackupNow(force: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de sauvegarde : $e')),
        );
      }
    }
  }

  Future<void> _handleRestoreFromDrive() async {
    try {
      final hasPwd = await _driveService.hasMasterPassword();
      String? password;

      if (!hasPwd) {
        if (!mounted) return;
        final pwdController = TextEditingController();
        final entered = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Mot de passe de la sauvegarde'),
            content: TextField(
              controller: pwdController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe ou clé de secours',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, pwdController.text),
                child: const Text('Valider'),
              ),
            ],
          ),
        );
        if (entered == null || entered.isEmpty) return;
        password = entered;
      }

      // Download and analyze
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Téléchargement depuis Google Drive...'),
                ],
              ),
            ),
          ),
        ),
      );

      final bundle = await _driveService.downloadBackup(password: password);
      final report = await MergeService().analyzeMerge(bundle.data);

      if (mounted) Navigator.pop(context); // Dismiss loading dialog

      if (!mounted) return;
      final restored = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => RestorePreviewScreen(
            bundle: bundle,
            initialReport: report,
            driveService: _driveService,
          ),
        ),
      );

      if (restored == true) {
        await _loadSettings();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Erreur'),
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
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 Mo';
    final mb = bytes / (1024 * 1024);
    if (mb < 1) return '${(bytes / 1024).toStringAsFixed(0)} Ko';
    return '${mb.toStringAsFixed(1)} Mo';
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'Jamais';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }

  Widget _buildStatusBadge() {
    IconData icon;
    Color color;
    String text;

    switch (_autoBackupService.status) {
      case AutoBackupStatus.upToDate:
        icon = Icons.check_circle;
        color = AppColors.used;
        text = 'À jour';
        break;
      case AutoBackupStatus.waitingConnection:
        icon = Icons.hourglass_top;
        color = AppColors.inStock;
        text = 'En attente de connexion';
        break;
      case AutoBackupStatus.wifiRequired:
        icon = Icons.pause_circle;
        color = AppColors.inStock;
        text = 'Wi-Fi requis';
        break;
      case AutoBackupStatus.inProgress:
        icon = Icons.sync;
        color = AppColors.primary;
        text = _autoBackupService.imageProgressTotal > 0
            ? 'Photos: ${_autoBackupService.imageProgressCurrent}/${_autoBackupService.imageProgressTotal}'
            : 'Sauvegarde en cours...';
        break;
      case AutoBackupStatus.dropBlocked:
        icon = Icons.warning_amber_rounded;
        color = AppColors.danger;
        text = 'Baisse de chèques détectée';
        break;
      case AutoBackupStatus.conflict:
        icon = Icons.warning;
        color = AppColors.inStock;
        text = 'Conflit multi-appareils';
        break;
      case AutoBackupStatus.failed:
        icon = Icons.error_outline;
        color = AppColors.danger;
        text = 'Échec de sauvegarde';
        break;
      case AutoBackupStatus.disabled:
        icon = Icons.cloud_off;
        color = AppColors.textSecondary;
        text = 'Désactivée';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sauvegarde Google Drive'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Account Header Card
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _accountInfo == null
                          ? Column(
                              children: [
                                const Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.primary),
                                const SizedBox(height: 10),
                                const Text(
                                  'Connecter Google Drive',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Sauvegardez vos données et photos automatiquement avec remplacement sécurisé et restauration sans perte.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.account_circle),
                                  label: const Text('Se connecter avec Google'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  onPressed: _handleSignIn,
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.primaryLight,
                                      child: const Icon(Icons.person, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _accountInfo!.displayName ?? 'Google Drive',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          Text(
                                            _accountInfo!.email,
                                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.check_circle, color: AppColors.used, size: 20),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('État : ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                    _buildStatusBadge(),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),

                  if (_accountInfo != null) ...[
                    const SizedBox(height: 20),

                    // Auto-backup configuration card
                    Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: _autoBackupEnabled,
                            activeTrackColor: AppColors.used,
                            title: const Text('Sauvegarde automatique', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            subtitle: const Text('Envoi automatique vers Drive dès que les conditions sont réunies', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            onChanged: (val) async {
                              setState(() => _autoBackupEnabled = val);
                              await _appMetaDao.setBool('auto_backup_enabled', val);
                              await _autoBackupService.refreshStatus();
                            },
                          ),
                          if (_autoBackupEnabled) ...[
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: RadioGroup<String>(
                                groupValue: _frequency,
                                onChanged: (val) async {
                                  if (val != null) {
                                    setState(() => _frequency = val);
                                    await _appMetaDao.setValue('auto_backup_frequency', val);
                                  }
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Fréquence :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    RadioListTile<String>(
                                      dense: true,
                                      value: 'after_edit',
                                      title: Text('Après chaque modification (2 min)', style: TextStyle(fontSize: 13)),
                                    ),
                                    RadioListTile<String>(
                                      dense: true,
                                      value: 'daily',
                                      title: Text('Chaque jour (la nuit)', style: TextStyle(fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const Divider(height: 1),
                          SwitchListTile(
                            value: _wifiOnly,
                            activeTrackColor: AppColors.used,
                            title: const Text('Wi-Fi seulement (images)', style: TextStyle(fontSize: 14)),
                            subtitle: const Text('Économise le forfait de données mobiles', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                            onChanged: (val) async {
                              setState(() => _wifiOnly = val);
                              await _appMetaDao.setBool('auto_backup_wifi_only', val);
                            },
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: RadioGroup<int>(
                              groupValue: _keepVersions,
                              onChanged: (val) async {
                                if (val != null) {
                                  setState(() => _keepVersions = val);
                                  await _appMetaDao.setInt('auto_backup_keep_versions', val);
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Versions conservées sur Drive :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RadioListTile<int>(
                                          dense: true,
                                          value: 2,
                                          title: Text('2 (recommandé)', style: TextStyle(fontSize: 12.5)),
                                        ),
                                      ),
                                      Expanded(
                                        child: RadioListTile<int>(
                                          dense: true,
                                          value: 1,
                                          title: Text('1 seulement', style: TextStyle(fontSize: 12.5)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            value: _includeImages,
                            activeTrackColor: AppColors.used,
                            title: const Text('Inclure les photos des chèques', style: TextStyle(fontSize: 14)),
                            subtitle: const Text('Sauvegarde incrémentale (une seule fois par photo)', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                            onChanged: (val) async {
                              setState(() => _includeImages = val);
                              await _appMetaDao.setBool('auto_backup_include_images', val);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Information Card
                    Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Dernière sauvegarde :', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                Text(_formatDate(_lastBackupAt), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Contenu sauvegardé :', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                Text(
                                  '$_lastChecksCount chèque(s) · $_lastImagesCount photo(s)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Espace utilisé sur Drive :', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                Text(_formatBytes(_driveUsedBytes), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            if (_recoveryCode != null) ...[
                              const Divider(height: 20),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.key, color: AppColors.primary),
                                title: const Text('Clé de secours', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                subtitle: const Text('Afficher le code de récupération', style: TextStyle(fontSize: 11.5)),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: _showRecoveryCodeDialog,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _autoBackupService.isBackingUp
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.cloud_upload),
                      label: const Text('Sauvegarder maintenant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: _autoBackupService.isBackingUp ? null : () => _handleBackupNow(),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.cloud_download, color: AppColors.primary),
                      label: const Text('Restaurer depuis Drive', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: _autoBackupService.isBackingUp ? null : _handleRestoreFromDrive,
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Déconnecter le compte'),
                      onPressed: _handleSignOut,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
