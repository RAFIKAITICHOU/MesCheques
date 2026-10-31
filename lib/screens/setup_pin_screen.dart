import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../widgets/pin_pad.dart';
import 'recovery_code_screen.dart';

class SetupPinScreen extends StatefulWidget {
  final String? recoveryCodeToReset;

  const SetupPinScreen({
    super.key,
    this.recoveryCodeToReset,
  });

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  int _pinLength = 6;
  int _step = 1; // 1: Enter PIN, 2: Confirm PIN
  String _firstPin = '';
  String _confirmPin = '';
  String? _errorMessage;
  bool _shake = false;

  void _onPinChanged(String val) {
    setState(() {
      _errorMessage = null;
      _shake = false;
      if (_step == 1) {
        _firstPin = val;
        if (_firstPin.length == _pinLength) {
          _validateFirstPin();
        }
      } else {
        _confirmPin = val;
        if (_confirmPin.length == _pinLength) {
          _validateConfirmPin();
        }
      }
    });
  }

  void _validateFirstPin() {
    final l10n = AppLocalizations.of(context)!;
    final weakError = AuthService.validatePinStrength(_firstPin);
    if (weakError != null) {
      setState(() {
        _shake = true;
        _errorMessage = _getWeakErrorMessage(weakError, l10n);
        _firstPin = '';
      });
      return;
    }

    // Move to step 2 (Confirm)
    setState(() {
      _step = 2;
      _confirmPin = '';
    });
  }

  void _validateConfirmPin() async {
    final l10n = AppLocalizations.of(context)!;
    if (_firstPin != _confirmPin) {
      setState(() {
        _shake = true;
        _errorMessage = l10n.pinMismatchError;
        _confirmPin = '';
      });
      return;
    }

    // PIN matched!
    final auth = context.read<AuthProvider>();

    // If resetting with recovery code, save directly
    if (widget.recoveryCodeToReset != null) {
      await auth.resetPinWithRecoveryCode(
        recoveryCode: widget.recoveryCodeToReset!,
        newPin: _firstPin,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pinResetSuccess)),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    }

    // Otherwise (first launch): propose biometrics if available, then show recovery code
    bool enableBiometrics = false;
    if (auth.isBiometricAvailable) {
      enableBiometrics = await _showBiometricDialog(l10n);
    }

    final recoveryCode = AuthService.generateRecoveryCode();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RecoveryCodeScreen(
          mode: RecoveryCodeMode.display,
          generatedCode: recoveryCode,
          pendingPin: _firstPin,
          pendingBiometric: enableBiometrics,
        ),
      ),
    );
  }

  Future<bool> _showBiometricDialog(AppLocalizations l10n) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.fingerprint, color: AppColors.primary, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(l10n.enableBiometricDialogTitle)),
          ],
        ),
        content: Text(l10n.enableBiometricDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.laterButton),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.enableButton),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _getWeakErrorMessage(PinValidationError err, AppLocalizations l10n) {
    switch (err) {
      case PinValidationError.allIdentical:
        return l10n.pinErrorAllIdentical;
      case PinValidationError.sequentialAscending:
        return l10n.pinErrorSequentialAscending;
      case PinValidationError.sequentialDescending:
        return l10n.pinErrorSequentialDescending;
      default:
        return l10n.pinErrorTooSimple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isReset = widget.recoveryCodeToReset != null;

    return Scaffold(
      appBar: isReset
          ? AppBar(
              title: Text(l10n.resetPinTitle),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Logo & App Name
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 38,
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
              const SizedBox(height: 6),
              Text(
                _step == 1
                    ? (isReset ? l10n.enterNewPin : l10n.createSecretPin)
                    : l10n.confirmSecretPin,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 16),

              // PIN length selector (only shown during step 1 if not reset)
              if (_step == 1 && !isReset)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLengthTab(4, l10n.pinLengthDigits(4)),
                      _buildLengthTab(6, l10n.pinLengthDigits(6)),
                    ],
                  ),
                ),

              // Stepper indicator
              Text(
                _step == 1 ? l10n.setupStep1Of2 : l10n.setupStep2Of2,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
                ),
              ),

              const SizedBox(height: 24),

              // PinPad
              PinPad(
                pinLength: _pinLength,
                pin: _step == 1 ? _firstPin : _confirmPin,
                onPinChanged: _onPinChanged,
                shake: _shake,
              ),

              const SizedBox(height: 16),

              // Error message
              if (_errorMessage != null)
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

              if (_step == 2) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _step = 1;
                      _confirmPin = '';
                      _firstPin = '';
                      _errorMessage = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: Text(l10n.backToFirstStep),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLengthTab(int length, String label) {
    final isSelected = _pinLength == length;
    return GestureDetector(
      onTap: () {
        setState(() {
          _pinLength = length;
          _firstPin = '';
          _confirmPin = '';
          _errorMessage = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
