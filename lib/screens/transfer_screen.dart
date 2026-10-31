import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../l10n/app_localizations.dart';
import '../providers/checks_provider.dart';
import '../services/backup_service.dart';
import '../services/merge_service.dart';
import '../services/transfer_service.dart';
import '../utils/constants.dart';
import 'merge_preview_screen.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final BackupService _backupService = BackupService();
  final MergeService _mergeService = MergeService();
  final TransferService _transferService = TransferService();

  bool _isProcessing = false;

  @override
  void dispose() {
    _transferService.stopServer();
    super.dispose();
  }

  // -------------------------------------------------------------
  // SEND METHODS
  // -------------------------------------------------------------

  Future<void> _handleSendByFile() async {
    final l10n = AppLocalizations.of(context)!;
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
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
                Navigator.pop(ctx, passwordController.text);
              }
            },
            child: Text(l10n.backupAndShare),
          ),
        ],
      ),
    );

    if (password != null && mounted) {
      setState(() => _isProcessing = true);
      try {
        await _backupService.createAndShareBackup(password);
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

  Future<void> _handleSendByQr() async {
    final l10n = AppLocalizations.of(context)!;
    final pin = TransferService.generatePin();

    setState(() => _isProcessing = true);

    TransferServerInfo? serverInfo;
    try {
      serverInfo = await _transferService.startTransferServer(
        pin: pin,
        onTransferDone: (success) {
          if (mounted && success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.transferSuccessServer)),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur serveur direct : $e')),
        );
      }
      setState(() => _isProcessing = false);
      return;
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.qr_code_2, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    l10n.qrShareTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.qrShareInstructions,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // QR Code View
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: QrImageView(
                  data: serverInfo!.toQrString(),
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 14),

              // PIN Code
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${l10n.transferPinLabel} : ',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.primaryDark),
                    ),
                    Text(
                      serverInfo.pin,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primary, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'IP : ${serverInfo.ip}:${serverInfo.port}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  await _transferService.stopServer();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                icon: const Icon(Icons.stop_circle_outlined, size: 18),
                label: Text(l10n.stopSharing),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await _transferService.stopServer();
  }

  // -------------------------------------------------------------
  // RECEIVE METHODS
  // -------------------------------------------------------------

  Future<void> _handleReceiveByFile() async {
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

    setState(() => _isProcessing = true);
    Map<String, dynamic>? data;
    try {
      data = await _backupService.decryptFile(file: file, password: password);
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Erreur'),
            content: Text(e is FormatException ? e.message : 'Erreur: $e'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.understood)),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }

    if (data != null && mounted) {
      await _processReceivedData(data);
    }
  }

  Future<void> _handleReceiveByQr() async {
    final l10n = AppLocalizations.of(context)!;

    final scannedInfo = await showModalBottomSheet<TransferServerInfo>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.75,
        child: Column(
          children: [
            AppBar(
              title: Text(l10n.scanQrTitle),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _handleManualDirectConnection();
                  },
                  child: Text(l10n.manualConnection),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                l10n.scanQrInstructions,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: MobileScanner(
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final rawValue = barcode.rawValue;
                      if (rawValue != null) {
                        final info = TransferServerInfo.parseQrString(rawValue);
                        if (info != null) {
                          Navigator.pop(ctx, info);
                          break;
                        }
                      }
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (scannedInfo == null || !mounted) return;

    setState(() => _isProcessing = true);
    Map<String, dynamic>? data;
    try {
      data = await _transferService.fetchDirectTransfer(
        ip: scannedInfo.ip,
        port: scannedInfo.port,
        token: scannedInfo.token,
        pin: scannedInfo.pin,
      );
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Erreur'),
            content: Text('Impossible de récupérer les données : $e'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.understood)),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }

    if (data != null && mounted) {
      await _processReceivedData(data);
    }
  }

  Future<void> _handleManualDirectConnection() async {
    final l10n = AppLocalizations.of(context)!;
    final ipController = TextEditingController();
    final portController = TextEditingController();
    final pinController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.manualConnection),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              decoration: InputDecoration(labelText: l10n.ipAddress, hintText: 'ex: 192.168.1.15'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: portController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.port, hintText: 'ex: 8888'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.transferPinLabel, hintText: 'ex: 1234'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.confirm)),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ip = ipController.text.trim();
    final port = int.tryParse(portController.text.trim()) ?? 0;
    final pin = pinController.text.trim();

    if (ip.isEmpty || port <= 0 || pin.isEmpty) return;

    setState(() => _isProcessing = true);
    Map<String, dynamic>? data;
    try {
      data = await _transferService.fetchDirectTransfer(
        ip: ip,
        port: port,
        token: '', // default
        pin: pin,
      );
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Erreur'),
            content: Text('Impossible de récupérer les données : $e'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.understood)),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }

    if (data != null && mounted) {
      await _processReceivedData(data);
    }
  }

  // -------------------------------------------------------------
  // IMPORT MODE SELECTION & EXECUTION (REPLACE vs MERGE)
  // -------------------------------------------------------------

  Future<void> _processReceivedData(Map<String, dynamic> data) async {
    final l10n = AppLocalizations.of(context)!;

    final mode = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.chooseImportMode,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Mode Fusionner (Recommended)
              Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.merge_type, color: AppColors.primary),
                  ),
                  title: Text(
                    l10n.modeMerge,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(l10n.modeMergeDesc, style: const TextStyle(fontSize: 12.5)),
                  ),
                  onTap: () => Navigator.pop(ctx, 'merge'),
                ),
              ),
              const SizedBox(height: 12),

              // Mode Remplacer
              Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_sweep_outlined, color: AppColors.danger),
                  ),
                  title: Text(
                    l10n.modeReplace,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.danger),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(l10n.modeReplaceDesc, style: const TextStyle(fontSize: 12.5)),
                  ),
                  onTap: () => Navigator.pop(ctx, 'replace'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    if (mode == null || !mounted) return;

    if (mode == 'replace') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.warning),
          content: Text(l10n.restoreWarningDesc),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: Text(l10n.restoreNow),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        setState(() => _isProcessing = true);
        try {
          await _mergeService.applyReplace(data: data);
          if (!mounted) return;
          await context.read<ChecksProvider>().refreshAll();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.restoreSuccess)),
          );
          Navigator.pop(context);
        } catch (e) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.restoreFailed),
                content: Text('Erreur: $e'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.understood)),
                ],
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isProcessing = false);
        }
      }
    } else if (mode == 'merge') {
      // Analyze merge report
      setState(() => _isProcessing = true);
      try {
        final report = await _mergeService.analyzeMerge(data);
        if (mounted) {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => MergePreviewScreen(
                data: data,
                initialReport: report,
              ),
            ),
          );
          if (result == true && mounted) {
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Erreur'),
              content: Text('Impossible d\'analyser les données : $e'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.understood)),
              ],
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transfer),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            if (_isProcessing) ...[
              const Center(child: LinearProgressIndicator()),
              const SizedBox(height: 12),
            ],

            // Section 1: Envoyer
            _buildSectionHeader(l10n.sendToPhone.toUpperCase(), Icons.upload_rounded, AppColors.primary),
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
                      child: const Icon(Icons.share_outlined, color: AppColors.primary),
                    ),
                    title: Text(l10n.sendByFile, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                    subtitle: Text(l10n.sendByFileDesc, style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _isProcessing ? null : _handleSendByFile,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.inStockBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.qr_code, color: AppColors.inStock),
                    ),
                    title: Text(l10n.sendByQr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                    subtitle: Text(l10n.sendByQrDesc, style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _isProcessing ? null : _handleSendByQr,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: Recevoir
            _buildSectionHeader(l10n.receiveFromPhone.toUpperCase(), Icons.download_rounded, AppColors.used),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.usedBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.file_open_outlined, color: AppColors.used),
                    ),
                    title: Text(l10n.receiveByFile, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                    subtitle: Text(l10n.receiveByFileDesc, style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _isProcessing ? null : _handleReceiveByFile,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                    ),
                    title: Text(l10n.receiveByQr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                    subtitle: Text(l10n.receiveByQrDesc, style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _isProcessing ? null : _handleReceiveByQr,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
