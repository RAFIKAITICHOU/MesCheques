import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/pin_pad.dart';
import 'recovery_code_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _enteredPin = '';
  String? _errorMessage;
  bool _shake = false;
  bool _hasPromptedBiometricsOnLaunch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptBiometric();
    });
  }

  void _checkAndPromptBiometric() {
    final auth = context.read<AuthProvider>();
    if (!_hasPromptedBiometricsOnLaunch &&
        auth.isBiometricEnabled &&
        auth.isBiometricAvailable &&
        !auth.isLockedOut) {
      _hasPromptedBiometricsOnLaunch = true;
      _triggerBiometrics();
    }
  }

  Future<void> _triggerBiometrics() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    await auth.unlockWithBiometric(reason: l10n.biometricPromptReason);
  }

  void _onPinChanged(String val) async {
    final auth = context.read<AuthProvider>();
    if (auth.isLockedOut) return;

    setState(() {
      _enteredPin = val;
      _errorMessage = null;
      _shake = false;
    });

    if (_enteredPin.length == auth.pinLength) {
      final success = await auth.unlockWithPin(_enteredPin);
      if (!mounted) return;

      if (!success) {
        setState(() {
          _shake = true;
          _enteredPin = '';
          final l10n = AppLocalizations.of(context)!;
          if (auth.isLockedOut) {
            _errorMessage = l10n.lockoutNotice(auth.lockoutRemainingSeconds);
          } else {
            _errorMessage = l10n.incorrectPinNotice(auth.attemptsBeforeLockout);
          }
        });
      }
    }
  }

  void _showForgotPinSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.help_outline, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    l10n.forgotPinTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                l10n.forgotPinExplanation,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),

              // Option 1: Use Recovery Code
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.vpn_key_outlined, color: AppColors.primary),
                ),
                title: Text(
                  l10n.resetWithRecoveryCodeOption,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(l10n.resetWithRecoveryCodeSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RecoveryCodeScreen(
                        mode: RecoveryCodeMode.reset,
                      ),
                    ),
                  );
                },
              ),

              const Divider(height: 20),

              // Option 2: Restore from Backup
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.settings_backup_restore, color: Colors.blue),
                ),
                title: Text(
                  l10n.restoreFromBackupOption,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(l10n.restoreFromBackupSubtitle),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showRestoreInfoDialog(l10n);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRestoreInfoDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.restoreFromBackupOption),
        content: Text(
          l10n.restoreFromBackupInfoMessage,
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.closeButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // MesCheques Lock Badge
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'MesCheques',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  auth.isLockedOut
                      ? l10n.appLockedOutHeading
                      : l10n.enterYourPinPrompt,
                  style: TextStyle(
                    fontSize: 15,
                    color: auth.isLockedOut ? AppColors.accentDanger : AppColors.textSecondary,
                    fontWeight: auth.isLockedOut ? FontWeight.bold : FontWeight.normal,
                  ),
                ),

                const SizedBox(height: 28),

                // PinPad
                PinPad(
                  pinLength: auth.pinLength,
                  pin: _enteredPin,
                  onPinChanged: _onPinChanged,
                  showBiometric: auth.isBiometricEnabled && auth.isBiometricAvailable,
                  onBiometricPressed: _triggerBiometrics,
                  isLockedOut: auth.isLockedOut,
                  shake: _shake,
                ),

                const SizedBox(height: 18),

                // Error / Lockout countdown banner
                if (auth.isLockedOut)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.accentDanger.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.accentDanger.withAlpha(80)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, color: AppColors.accentDanger, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          l10n.lockoutNotice(auth.lockoutRemainingSeconds),
                          style: const TextStyle(
                            color: AppColors.accentDanger,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.accentDanger,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Forgot PIN link
                TextButton(
                  onPressed: _showForgotPinSheet,
                  child: Text(
                    l10n.forgotPinButton,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
