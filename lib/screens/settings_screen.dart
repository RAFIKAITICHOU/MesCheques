import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/checks_provider.dart';
import '../providers/locale_provider.dart';
import '../services/backup_service.dart';
import '../utils/constants.dart';
import 'drive_settings_screen.dart';
import 'security_settings_screen.dart';
import 'transfer_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackupService _backupService = BackupService();
  bool _isProcessing = false;

  Future<void> _handleBackup() async {
    final l10n = AppLocalizations.of(context)!;
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final passwordData = await showDialog<({String password, bool includeImages})>(
      context: context,
      builder: (ctx) {
        bool includeImages = true;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.encryptBackup,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.backupPasswordPrompt,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.passwordLabel,
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.length < 4) {
                          return l10n.passwordMinLength;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: confirmController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.confirmPasswordLabel,
                        prefixIcon: const Icon(Icons.lock_reset, size: 20),
                      ),
                      validator: (val) {
                        if (val != passwordController.text) {
                          return l10n.passwordsDoNotMatch;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: includeImages,
                      onChanged: (val) => setDialogState(() => includeImages = val ?? true),
                      title: Text(l10n.backupIncludeImages, style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                        includeImages ? l10n.backupWithImages : l10n.backupDataOnly,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(ctx, (password: passwordController.text, includeImages: includeImages));
                    }
                  },
                  child: Text(l10n.backupAndShare),
                ),
              ],
            );
          },
        );
      },
    );

    if (passwordData != null && mounted) {
      setState(() => _isProcessing = true);
      try {
        await _backupService.createAndShareBackup(
          passwordData.password,
          includeImages: passwordData.includeImages,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.backupSuccess)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.backupError(e.toString()))),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleRestore() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isProcessing = true);
    File? file;
    try {
      file = await _backupService.pickBackupFile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.fileSelectionError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }

    if (file == null || !mounted) return;

    final passwordController = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock_open_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.passwordRequired, overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.fileSelected(file!.path.split("/").last),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.enterBackupPassword,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.passwordLabel.replaceAll(' *', ''),
                prefixIcon: const Icon(Icons.key, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, passwordController.text),
            child: Text(l10n.validate),
          ),
        ],
      ),
    );

    if (password == null || password.isEmpty || !mounted) return;

    // Warning confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.warning, overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: Text(l10n.restoreWarningDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(l10n.restoreNow),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<ChecksProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isProcessing = true);
    try {
      await _backupService.restoreBackupFromFile(
        file: file,
        password: password,
      );

      if (mounted) {
        await provider.refreshAll();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.restoreSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.restoreFailed),
            content: Text(
              e is FormatException ? e.message : 'Erreur inattendue : $e',
            ),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: LinearProgressIndicator()),
              ),

            // Card Langue
            _buildSectionTitle(l10n.language.toUpperCase()),
            Card(
              margin: EdgeInsets.zero,
              child: RadioGroup<String>(
                groupValue: localeProvider.locale.languageCode,
                onChanged: (val) {
                  if (val != null) localeProvider.setLocale(val);
                },
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          const Text('🇫🇷', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Text(
                            l10n.french,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ],
                      ),
                      value: 'fr',
                      activeColor: AppColors.primary,
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          const Text('🇲🇦', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Text(
                            l10n.arabic,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                      value: 'ar',
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Card Sécurité de l'application
            _buildSectionTitle(l10n.securitySection),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppColors.primary),
                ),
                title: Text(
                  l10n.securitySettingsTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: Text(
                  l10n.securitySettingsDesc,
                  style: const TextStyle(fontSize: 12.5),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Card Transfert entre téléphones
            _buildSectionTitle(l10n.transferSection),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sync_alt_rounded, color: AppColors.primary),
                ),
                title: Text(
                  l10n.transfer,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: Text(
                  l10n.transferSectionDesc,
                  style: const TextStyle(fontSize: 12.5),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TransferScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Card Sauvegarde & Restauration
            _buildSectionTitle(l10n.dataAndSecurity),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.cloud_sync, color: AppColors.primary),
                    ),
                    title: const Text(
                      'Sauvegarde Google Drive',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: const Text(
                      'Automatique, remplacement et restauration sans perte',
                      style: TextStyle(fontSize: 12.5),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DriveSettingsScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
                    ),
                    title: Text(
                      l10n.createBackup,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Text(
                      l10n.createBackupDesc,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _isProcessing ? null : _handleBackup,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.usedBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.cloud_download_outlined, color: AppColors.used),
                    ),
                    title: Text(
                      l10n.restoreBackup,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Text(
                      l10n.restoreBackupDesc,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _isProcessing ? null : _handleRestore,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Card Informations
            _buildSectionTitle(l10n.about),
            Card(
              margin: EdgeInsets.zero,
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
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.payments, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.appName,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              l10n.appVersion('1.0.0'),
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildInfoPoint(
                      icon: Icons.wifi_off_rounded,
                      title: l10n.offline100,
                      desc: l10n.offline100Desc,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoPoint(
                      icon: Icons.lock_outline,
                      title: l10n.aes256,
                      desc: l10n.aes256Desc,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoPoint(
                      icon: Icons.auto_delete_outlined,
                      title: l10n.trash15Days,
                      desc: l10n.trash15DaysDesc,
                    ),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.person_pin_rounded, size: 22, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${l10n.developerInfo} ${l10n.developerName}',
                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        l10n.developerRole,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      l10n.developerPhone,
                                      textDirection: TextDirection.ltr,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      l10n.developerEmail,
                                      textDirection: TextDirection.ltr,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildInfoPoint({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
