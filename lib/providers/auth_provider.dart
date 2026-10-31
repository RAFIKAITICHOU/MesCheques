import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/window_security_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final BiometricService _biometricService;

  bool _isInitialized = false;
  bool _hasPinSet = false;
  bool _isLocked = true;
  int _pinLength = 6;
  int _failedAttempts = 0;
  int _lockoutRemainingSeconds = 0;
  Timer? _lockoutTimer;

  bool _isBiometricEnabled = false;
  bool _isBiometricAvailable = false;
  int _lockTimeoutSeconds = 0; // 0 = immediately, 60 = 1 min, 300 = 5 min
  bool _isSecureWindowEnabled = true;

  DateTime? _pausedAt;

  VoidCallback? onAuthenticated;

  AuthProvider({
    AuthService? authService,
    BiometricService? biometricService,
  })  : _authService = authService ?? AuthService(),
        _biometricService = biometricService ?? BiometricService();

  bool get isInitialized => _isInitialized;
  bool get hasPinSet => _hasPinSet;
  bool get isLocked => _isLocked;
  int get pinLength => _pinLength;
  int get failedAttempts => _failedAttempts;
  int get lockoutRemainingSeconds => _lockoutRemainingSeconds;
  bool get isLockedOut => _lockoutRemainingSeconds > 0;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isBiometricAvailable => _isBiometricAvailable;
  int get lockTimeoutSeconds => _lockTimeoutSeconds;
  bool get isSecureWindowEnabled => _isSecureWindowEnabled;

  /// Number of attempts remaining before entering lockout
  int get attemptsBeforeLockout {
    final remaining = 5 - _failedAttempts;
    return remaining > 0 ? remaining : 0;
  }

  /// Initialize state from secure storage
  Future<void> init() async {
    _hasPinSet = await _authService.hasPin();
    _pinLength = await _authService.getPinLength();
    _isBiometricEnabled = await _authService.isBiometricEnabled();
    _isBiometricAvailable = await _biometricService.canCheckBiometrics();
    _lockTimeoutSeconds = await _authService.getLockTimeoutSeconds();
    _isSecureWindowEnabled = await _authService.isSecureWindowEnabled();
    _failedAttempts = await _authService.getFailedAttempts();

    // Apply FLAG_SECURE
    await WindowSecurityService.setSecure(_isSecureWindowEnabled);

    // Check existing lockout
    _lockoutRemainingSeconds = await _authService.getLockoutRemainingSeconds();
    if (_lockoutRemainingSeconds > 0) {
      _startLockoutCountdown();
    }

    // If no PIN has been created yet, app is not locked, but waiting for setup
    _isLocked = _hasPinSet;
    _isInitialized = true;
    notifyListeners();
  }

  void _startLockoutCountdown() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockoutRemainingSeconds > 1) {
        _lockoutRemainingSeconds--;
        notifyListeners();
      } else {
        _lockoutRemainingSeconds = 0;
        timer.cancel();
        notifyListeners();
      }
    });
  }

  /// Attempt unlocking with entered PIN
  Future<bool> unlockWithPin(String pin) async {
    if (isLockedOut) return false;

    final isValid = await _authService.verifyPin(pin);
    if (isValid) {
      await _authService.resetFailedAttempts();
      _failedAttempts = 0;
      _lockoutRemainingSeconds = 0;
      _lockoutTimer?.cancel();
      _isLocked = false;
      notifyListeners();
      onAuthenticated?.call();
      return true;
    } else {
      _failedAttempts = await _authService.recordFailedAttempt();
      _lockoutRemainingSeconds = await _authService.getLockoutRemainingSeconds();
      if (_lockoutRemainingSeconds > 0) {
        _startLockoutCountdown();
      }
      notifyListeners();
      return false;
    }
  }

  /// Attempt unlocking via biometric prompt
  Future<bool> unlockWithBiometric({required String reason}) async {
    if (isLockedOut) return false;
    if (!_isBiometricEnabled || !_isBiometricAvailable) return false;

    final authenticated = await _biometricService.authenticate(localizedReason: reason);
    if (authenticated) {
      await _authService.resetFailedAttempts();
      _failedAttempts = 0;
      _lockoutRemainingSeconds = 0;
      _lockoutTimer?.cancel();
      _isLocked = false;
      notifyListeners();
      onAuthenticated?.call();
      return true;
    }
    return false;
  }

  /// Initial setup of PIN & Recovery Code
  Future<void> setupPin({
    required String pin,
    required String recoveryCode,
    bool enableBiometric = false,
  }) async {
    await _authService.setupPin(
      pin: pin,
      recoveryCode: recoveryCode,
      enableBiometric: enableBiometric,
    );

    _hasPinSet = true;
    _pinLength = pin.length;
    _isBiometricEnabled = enableBiometric;
    _isBiometricAvailable = await _biometricService.canCheckBiometrics();
    _failedAttempts = 0;
    _lockoutRemainingSeconds = 0;
    _isLocked = false;
    notifyListeners();
    onAuthenticated?.call();
  }

  /// Change existing PIN
  Future<bool> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    final success = await _authService.changePin(oldPin: oldPin, newPin: newPin);
    if (success) {
      _pinLength = newPin.length;
      notifyListeners();
    }
    return success;
  }

  /// Verify recovery code
  Future<bool> verifyRecoveryCode(String code) async {
    return await _authService.verifyRecoveryCode(code);
  }

  /// Reset PIN with recovery code
  Future<bool> resetPinWithRecoveryCode({
    required String recoveryCode,
    required String newPin,
  }) async {
    final success = await _authService.resetPinWithRecoveryCode(
      recoveryCode: recoveryCode,
      newPin: newPin,
    );

    if (success) {
      _pinLength = newPin.length;
      _failedAttempts = 0;
      _lockoutRemainingSeconds = 0;
      _lockoutTimer?.cancel();
      _isLocked = false;
      notifyListeners();
      onAuthenticated?.call();
    }
    return success;
  }

  /// Toggle Biometrics
  Future<void> setBiometricEnabled(bool enabled) async {
    await _authService.setBiometricEnabled(enabled);
    _isBiometricEnabled = enabled;
    _isBiometricAvailable = await _biometricService.canCheckBiometrics();
    notifyListeners();
  }

  /// Change auto-lock delay timeout
  Future<void> setLockTimeout(int seconds) async {
    await _authService.setLockTimeoutSeconds(seconds);
    _lockTimeoutSeconds = seconds;
    notifyListeners();
  }

  /// Toggle FLAG_SECURE
  Future<void> setSecureWindow(bool enabled) async {
    await _authService.setSecureWindowEnabled(enabled);
    _isSecureWindowEnabled = enabled;
    await WindowSecurityService.setSecure(enabled);
    notifyListeners();
  }

  /// Force lock immediately
  void lockNow() {
    if (_hasPinSet) {
      _isLocked = true;
      notifyListeners();
    }
  }

  /// Lifecycle: called when app moves to background
  void onAppPaused() {
    if (!_hasPinSet) return;
    _pausedAt = DateTime.now();

    // If timeout is 0 (immediately), lock instantly
    if (_lockTimeoutSeconds == 0) {
      _isLocked = true;
      notifyListeners();
    }
  }

  /// Lifecycle: called when app returns to foreground
  void onAppResumed() {
    if (!_hasPinSet) return;

    if (_pausedAt != null && !_isLocked) {
      final elapsedSec = DateTime.now().difference(_pausedAt!).inSeconds;
      if (elapsedSec >= _lockTimeoutSeconds) {
        _isLocked = true;
        notifyListeners();
      }
    }
    _pausedAt = null;
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }
}
