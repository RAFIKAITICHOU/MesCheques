import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../widgets/pin_pad.dart';
import 'recovery_code_screen.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  void _showChangePinDialog() {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    String oldPin = '';
    String newPin = '';
    String confirmPin = '';
    int step = 1; // 1: old, 2: new, 3: confirm
    String? error;
    bool shake = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          void onPinEntered(String val) async {
            setModalState(() {
              error = null;
              shake = false;
            });

            if (step == 1) {
              oldPin = val;
              if (oldPin.length == auth.pinLength) {
                // Verify old pin
                final valid = await AuthService().verifyPin(oldPin);
                if (valid) {
                  setModalState(() {
                    step = 2;
                  });
                } else {
                  setModalState(() {
                    shake = true;
                    oldPin = '';
                    error = l10n.oldPinIncorrect;
                  });
                }
              }
            } else if (step == 2) {
              newPin = val;
              if (newPin.length == auth.pinLength) {
                final weak = AuthService.validatePinStrength(newPin);
                if (weak != null) {
                  setModalState(() {
                    shake = true;
                    newPin = '';
                    error = l10n.pinErrorTooSimple;
                  });
                  return;
                }
                setModalState(() {
                  step = 3;
                });
              }
            } else if (step == 3) {
              confirmPin = val;
              if (confirmPin.length == auth.pinLength) {
                if (confirmPin != newPin) {
                  setModalState(() {
                    shake = true;
                    confirmPin = '';
                    error = l10n.pinMismatchError;
                  });
                  return;
                }

                // Change PIN
                final changed = await auth.changePin(oldPin: oldPin, newPin: newPin);
                if (!ctx.mounted || !mounted) return;
                Navigator.of(ctx).pop();
                if (changed) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.pinChangeSuccess)),
                  );
                }
              }
            }
          }

          String stepTitle;
          if (step == 1) {
            stepTitle = l10n.enterCurrentPin;
          } else if (step == 2) {
            stepTitle = l10n.enterNewPin;
          } else {
            stepTitle = l10n.confirmNewPin;
          }

          String currentPin;
          if (step == 1) {
            currentPin = oldPin;
          } else if (step == 2) {
            currentPin = newPin;
          } else {
            currentPin = confirmPin;
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.modifyPinTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stepTitle,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),

                  PinPad(
                    pinLength: auth.pinLength,
                    pin: currentPin,
                    onPinChanged: onPinEntered,
                    shake: shake,
                  ),

                  const SizedBox(height: 12),
                  if (error != null)
                    Text(
                      error!,
                      style: const TextStyle(
                        color: AppColors.accentDanger,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTimeoutPicker() {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();

    final options = [
      {'sec': 0, 'label': l10n.lockTimeoutImmediately},
      {'sec': 60, 'label': l10n.lockTimeout1Min},
      {'sec': 300, 'label': l10n.lockTimeout5Min},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      l10n.lockTimeoutTitle,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ...options.map((opt) {
                final sec = opt['sec'] as int;
                final label = opt['label'] as String;
                final isSelected = auth.lockTimeoutSeconds == sec;

                return ListTile(
                  title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () {
                    auth.setLockTimeout(sec);
                    Navigator.of(ctx).pop();
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showRegenerateRecoveryCodeDialog() {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);

    String pin = '';
    String? error;
    bool shake = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          void onPinEntered(String val) async {
            setModalState(() {
              error = null;
              shake = false;
              pin = val;
            });

            if (pin.length == auth.pinLength) {
              final valid = await AuthService().verifyPin(pin);
              if (valid) {
                final newCode = AuthService.generateRecoveryCode();
                await auth.setupPin(
                  pin: pin,
                  recoveryCode: newCode,
                  enableBiometric: auth.isBiometricEnabled,
                );
                if (!ctx.mounted || !mounted) return;
                Navigator.of(ctx).pop();
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => RecoveryCodeScreen(
                      mode: RecoveryCodeMode.display,
                      generatedCode: newCode,
                      pendingPin: pin,
                      pendingBiometric: auth.isBiometricEnabled,
                    ),
                  ),
                );
              } else {
                setModalState(() {
                  shake = true;
                  pin = '';
                  error = l10n.oldPinIncorrect;
                });
              }
            }
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.generateNewRecoveryCodeTitle,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.enterPinToRevealRecoveryCode,
                    style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  PinPad(
                    pinLength: auth.pinLength,
                    pin: pin,
                    onPinChanged: onPinEntered,
                    shake: shake,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: AppColors.accentDanger,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();

    String timeoutLabel;
    switch (auth.lockTimeoutSeconds) {
      case 60:
        timeoutLabel = l10n.lockTimeout1Min;
        break;
      case 300:
        timeoutLabel = l10n.lockTimeout5Min;
        break;
      default:
        timeoutLabel = l10n.lockTimeoutImmediately;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.securitySettingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Section 1: Code PIN & Biometrics
          _buildSectionHeader(l10n.accessProtectionSectionHeader),
          ListTile(
            leading: const Icon(Icons.pin, color: AppColors.primary),
            title: Text(l10n.modifyPinTitle),
            subtitle: Text(l10n.modifyPinSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showChangePinDialog,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint, color: AppColors.primary),
            title: Text(l10n.biometricOptionTitle),
            subtitle: Text(
              auth.isBiometricAvailable
                  ? l10n.biometricOptionSubtitle
                  : l10n.biometricUnavailableSubtitle,
            ),
            value: auth.isBiometricEnabled,
            onChanged: auth.isBiometricAvailable
                ? (val) async {
                    if (val) {
                      // Test authenticate before enabling
                      final ok = await auth.unlockWithBiometric(
                        reason: l10n.biometricPromptReason,
                      );
                      if (ok) {
                        await auth.setBiometricEnabled(true);
                      }
                    } else {
                      await auth.setBiometricEnabled(false);
                    }
                  }
                : null,
          ),

          const Divider(height: 32),

          // Section 2: Auto-lock & Privacy
          _buildSectionHeader(l10n.privacySectionHeader),
          ListTile(
            leading: const Icon(Icons.timer_outlined, color: AppColors.primary),
            title: Text(l10n.lockTimeoutTitle),
            subtitle: Text(timeoutLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showTimeoutPicker,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.security, color: AppColors.primary),
            title: Text(l10n.secureWindowOptionTitle),
            subtitle: Text(l10n.secureWindowOptionSubtitle),
            value: auth.isSecureWindowEnabled,
            onChanged: (val) => auth.setSecureWindow(val),
          ),

          const Divider(height: 32),

          // Section 3: Recovery Code
          _buildSectionHeader(l10n.recoverySectionHeader),
          ListTile(
            leading: const Icon(Icons.vpn_key_outlined, color: AppColors.accentWarning),
            title: Text(l10n.generateNewRecoveryCodeTitle),
            subtitle: Text(l10n.generateNewRecoveryCodeSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showRegenerateRecoveryCodeDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
