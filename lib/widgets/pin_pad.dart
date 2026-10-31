import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class PinPad extends StatefulWidget {
  final int pinLength;
  final String pin;
  final ValueChanged<String> onPinChanged;
  final VoidCallback? onBiometricPressed;
  final bool showBiometric;
  final bool isLockedOut;
  final bool shake;

  const PinPad({
    super.key,
    required this.pinLength,
    required this.pin,
    required this.onPinChanged,
    this.onBiometricPressed,
    this.showBiometric = false,
    this.isLockedOut = false,
    this.shake = false,
  });

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant PinPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _shakeController.forward(from: 0.0);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigitTap(String digit) {
    if (widget.isLockedOut) return;
    if (widget.pin.length < widget.pinLength) {
      HapticFeedback.lightImpact();
      widget.onPinChanged(widget.pin + digit);
    }
  }

  void _onDeleteTap() {
    if (widget.isLockedOut) return;
    if (widget.pin.isNotEmpty) {
      HapticFeedback.lightImpact();
      widget.onPinChanged(widget.pin.substring(0, widget.pin.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dots row with shake animation
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.pinLength, (index) {
              final isFilled = index < widget.pin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isFilled ? AppColors.primary : AppColors.divider,
                    width: 2,
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 36),

        // Keypad grid (0-9 Latin digits)
        Directionality(
          textDirection: TextDirection.ltr, // Keep standard keypad layout
          child: Container(
            constraints: const BoxConstraints(maxWidth: 290),
            child: Column(
              children: [
                _buildRow(['1', '2', '3']),
                const SizedBox(height: 14),
                _buildRow(['4', '5', '6']),
                const SizedBox(height: 14),
                _buildRow(['7', '8', '9']),
                const SizedBox(height: 14),
                _buildBottomRow(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: digits.map((d) => _buildKey(d)).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left key: Biometric button or empty spacer
        widget.showBiometric
            ? _buildIconButton(
                icon: Icons.fingerprint,
                onTap: widget.isLockedOut ? null : widget.onBiometricPressed,
                color: AppColors.primary,
              )
            : const SizedBox(width: 72, height: 72),

        // Center key: '0'
        _buildKey('0'),

        // Right key: Backspace
        _buildIconButton(
          icon: Icons.backspace_outlined,
          onTap: widget.isLockedOut ? null : _onDeleteTap,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildKey(String digit) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: AppColors.cardBackground,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.isLockedOut ? null : () => _onDigitTap(digit),
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w500,
                color: widget.isLockedOut ? AppColors.textHint : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Icon(
              icon,
              size: 28,
              color: widget.isLockedOut ? AppColors.textHint : color,
            ),
          ),
        ),
      ),
    );
  }
}
