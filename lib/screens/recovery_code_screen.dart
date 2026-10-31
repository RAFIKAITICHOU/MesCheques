import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../widgets/lock_gate.dart';
import 'home_screen.dart';
import 'setup_pin_screen.dart';

enum RecoveryCodeMode {
  display, // Display code upon initial setup
  reset,   // Enter code to reset forgotten PIN
}

class RecoveryCodeScreen extends StatefulWidget {
  final RecoveryCodeMode mode;
  final String? generatedCode;
  final String? pendingPin;
  final bool pendingBiometric;

  const RecoveryCodeScreen({
    super.key,
    required this.mode,
    this.generatedCode,
    this.pendingPin,
    this.pendingBiometric = false,
  });

  @override
  State<RecoveryCodeScreen> createState() => _RecoveryCodeScreenState();
}

class _RecoveryCodeScreenState extends State<RecoveryCodeScreen> {
  bool _hasConfirmedWritten = false;
  final _inputController = TextEditingController();
  String? _errorMessage;
  bool _isVerifying = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _copyToClipboard() {
    if (widget.generatedCode != null) {
      Clipboard.setData(ClipboardData(text: widget.generatedCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.codeCopied),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _finalizeSetup() async {
    if (!_hasConfirmedWritten || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthProvider>();

      if (widget.pendingPin != null && widget.generatedCode != null) {
        await auth.setupPin(
          pin: widget.pendingPin!,
          recoveryCode: widget.generatedCode!,
          enableBiometric: widget.pendingBiometric,
        );
      }

      if (!mounted) return;

      // Navigate to the main home screen cleanly
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LockGate(
            child: HomeScreen(),
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.accentDanger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _verifyAndProceedToReset() async {
    final code = _inputController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final valid = await auth.verifyRecoveryCode(code);

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (valid) {
      // Navigate to choose a new PIN
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SetupPinScreen(
            recoveryCodeToReset: code,
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.recoveryCodeInvalid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == RecoveryCodeMode.display
            ? l10n.recoveryCodeTitle
            : l10n.recoveryCodeResetTitle),
        automaticallyImplyLeading: widget.mode == RecoveryCodeMode.reset,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: widget.mode == RecoveryCodeMode.display
              ? _buildDisplayView(l10n)
              : _buildResetView(l10n),
        ),
      ),
    );
  }

  Widget _buildDisplayView(AppLocalizations l10n) {
    final code = widget.generatedCode ?? AuthService.generateRecoveryCode();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        const Center(
          child: Icon(Icons.vpn_key_outlined, size: 60, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.recoveryCodeHeading,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.recoveryCodeDescription,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Recovery code box
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withAlpha(80), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              SelectableText(
                code,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                  fontFamily: 'monospace',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy, size: 18),
                label: Text(l10n.copyCode),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Warning banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accentWarning.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accentWarning.withAlpha(100)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.accentWarning, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.recoveryCodeWarning,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Checkbox confirmation
        CheckboxListTile(
          value: _hasConfirmedWritten,
          onChanged: (val) => setState(() => _hasConfirmedWritten = val ?? false),
          title: Text(
            l10n.recoveryCodeConfirmCheck,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),

        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: (_hasConfirmedWritten && !_isSubmitting) ? _finalizeSetup : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  l10n.finishSetupButton,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  Widget _buildResetView(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        const Center(
          child: Icon(Icons.lock_reset, size: 60, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.enterRecoveryCodeHeading,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.enterRecoveryCodeSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        TextField(
          controller: _inputController,
          autofocus: true,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            fontSize: 22,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
          decoration: InputDecoration(
            hintText: 'XXXX-XXXX-XXXX',
            errorText: _errorMessage,
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onChanged: (_) {
            if (_errorMessage != null) {
              setState(() => _errorMessage = null);
            }
          },
        ),

        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: _isVerifying ? null : _verifyAndProceedToReset,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isVerifying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  l10n.verifyRecoveryCodeButton,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
