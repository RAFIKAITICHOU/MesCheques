import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum PinValidationError {
  tooShort,
  allIdentical,
  sequentialAscending,
  sequentialDescending,
}

class AuthService {
  static const String _keyPinHash = 'auth_pin_hash';
  static const String _keyPinSalt = 'auth_pin_salt';
  static const String _keyPinLength = 'auth_pin_length';
  static const String _keyRecoveryCodeHash = 'auth_recovery_code_hash';
  static const String _keyFailedAttempts = 'auth_failed_attempts';
  static const String _keyLockedUntil = 'auth_locked_until';
  static const String _keyLastKnownTime = 'auth_last_known_time';
  static const String _keyBiometricEnabled = 'auth_biometric_enabled';
  static const String _keyLockTimeout = 'auth_lock_timeout';
  static const String _keySecureWindow = 'auth_secure_window';

  final FlutterSecureStorage _storage;

  AuthService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
            );

  // ---------------------------------------------------------------------------
  // PBKDF2-HMAC-SHA256 (RFC 2898)
  // ---------------------------------------------------------------------------
  static List<int> pbkdf2HmacSha256({
    required String password,
    required List<int> salt,
    int iterations = 10000,
    int keyLength = 32,
  }) {
    final passwordBytes = utf8.encode(password);
    final hmac = Hmac(sha256, passwordBytes);

    // Block 1 (i = 1) -> Salt || [0, 0, 0, 1]
    final saltAndBlock = Uint8List(salt.length + 4);
    saltAndBlock.setRange(0, salt.length, salt);
    saltAndBlock[salt.length + 3] = 1;

    var u = hmac.convert(saltAndBlock).bytes;
    final t = List<int>.from(u);

    for (int i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (int k = 0; k < t.length; k++) {
        t[k] ^= u[k];
      }
    }

    return t.sublist(0, keyLength);
  }

  // ---------------------------------------------------------------------------
  // Salt & Random generation
  // ---------------------------------------------------------------------------
  static List<int> generateSalt([int length = 16]) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }

  /// Generates a human-friendly recovery code: e.g. K7X9-2MQ4-PL83
  static String generateRecoveryCode() {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ'; // Avoid 0, O, 1, I
    final rnd = Random.secure();
    String chunk() => List.generate(4, (_) => chars[rnd.nextInt(chars.length)]).join();
    return '${chunk()}-${chunk()}-${chunk()}';
  }

  static String hashRecoveryCode(String code) {
    final clean = code.replaceAll('-', '').trim().toUpperCase();
    return sha256.convert(utf8.encode(clean)).toString();
  }

  // ---------------------------------------------------------------------------
  // PIN Validation (Weak PIN prevention)
  // ---------------------------------------------------------------------------
  static PinValidationError? validatePinStrength(String pin) {
    if (pin.length < 4) return PinValidationError.tooShort;

    // Check all identical: 0000, 111111...
    final first = pin[0];
    if (pin.split('').every((c) => c == first)) {
      return PinValidationError.allIdentical;
    }

    // Check sequential ascending: 1234, 0123, 123456...
    bool isAsc = true;
    for (int i = 0; i < pin.length - 1; i++) {
      final cur = int.tryParse(pin[i]);
      final next = int.tryParse(pin[i + 1]);
      if (cur == null || next == null || (next != cur + 1)) {
        isAsc = false;
        break;
      }
    }
    if (isAsc) return PinValidationError.sequentialAscending;

    // Check sequential descending: 4321, 654321...
    bool isDesc = true;
    for (int i = 0; i < pin.length - 1; i++) {
      final cur = int.tryParse(pin[i]);
      final next = int.tryParse(pin[i + 1]);
      if (cur == null || next == null || (next != cur - 1)) {
        isDesc = false;
        break;
      }
    }
    if (isDesc) return PinValidationError.sequentialDescending;

    return null;
  }

  // ---------------------------------------------------------------------------
  // Storage & State Queries
  // ---------------------------------------------------------------------------
  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _keyPinHash);
    return hash != null && hash.isNotEmpty;
  }

  Future<int> getPinLength() async {
    final len = await _storage.read(key: _keyPinLength);
    return int.tryParse(len ?? '6') ?? 6;
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyBiometricEnabled);
    return val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled ? 'true' : 'false');
  }

  Future<int> getLockTimeoutSeconds() async {
    final val = await _storage.read(key: _keyLockTimeout);
    return int.tryParse(val ?? '0') ?? 0; // Default 0 = immediately
  }

  Future<void> setLockTimeoutSeconds(int seconds) async {
    await _storage.write(key: _keyLockTimeout, value: seconds.toString());
  }

  Future<bool> isSecureWindowEnabled() async {
    final val = await _storage.read(key: _keySecureWindow);
    return val != 'false'; // Default true
  }

  Future<void> setSecureWindowEnabled(bool enabled) async {
    await _storage.write(key: _keySecureWindow, value: enabled ? 'true' : 'false');
  }

  // ---------------------------------------------------------------------------
  // Setup & PIN Management
  // ---------------------------------------------------------------------------
  Future<void> setupPin({
    required String pin,
    required String recoveryCode,
    bool enableBiometric = false,
  }) async {
    final salt = generateSalt();
    final hash = pbkdf2HmacSha256(password: pin, salt: salt);
    final recoveryHash = hashRecoveryCode(recoveryCode);

    await _storage.write(key: _keyPinSalt, value: base64Encode(salt));
    await _storage.write(key: _keyPinHash, value: base64Encode(hash));
    await _storage.write(key: _keyPinLength, value: pin.length.toString());
    await _storage.write(key: _keyRecoveryCodeHash, value: recoveryHash);
    await _storage.write(key: _keyBiometricEnabled, value: enableBiometric ? 'true' : 'false');
    await _storage.write(key: _keyFailedAttempts, value: '0');
    await _storage.write(key: _keyLockedUntil, value: '0');
    await _storage.write(
      key: _keyLastKnownTime,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: _keyPinHash);
    final storedSaltBase64 = await _storage.read(key: _keyPinSalt);

    if (storedHash == null || storedSaltBase64 == null) return false;

    final salt = base64Decode(storedSaltBase64);
    final computed = pbkdf2HmacSha256(password: pin, salt: salt);
    final computedBase64 = base64Encode(computed);

    return storedHash == computedBase64;
  }

  Future<bool> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    final ok = await verifyPin(oldPin);
    if (!ok) return false;

    final salt = generateSalt();
    final hash = pbkdf2HmacSha256(password: newPin, salt: salt);

    await _storage.write(key: _keyPinSalt, value: base64Encode(salt));
    await _storage.write(key: _keyPinHash, value: base64Encode(hash));
    await _storage.write(key: _keyPinLength, value: newPin.length.toString());
    return true;
  }

  // ---------------------------------------------------------------------------
  // Recovery Code Verification & Reset
  // ---------------------------------------------------------------------------
  Future<bool> verifyRecoveryCode(String code) async {
    final storedRecoveryHash = await _storage.read(key: _keyRecoveryCodeHash);
    if (storedRecoveryHash == null) return false;

    final inputHash = hashRecoveryCode(code);
    return storedRecoveryHash == inputHash;
  }

  Future<bool> resetPinWithRecoveryCode({
    required String recoveryCode,
    required String newPin,
  }) async {
    final valid = await verifyRecoveryCode(recoveryCode);
    if (!valid) return false;

    final salt = generateSalt();
    final hash = pbkdf2HmacSha256(password: newPin, salt: salt);

    await _storage.write(key: _keyPinSalt, value: base64Encode(salt));
    await _storage.write(key: _keyPinHash, value: base64Encode(hash));
    await _storage.write(key: _keyPinLength, value: newPin.length.toString());
    await resetFailedAttempts();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Lockout & Attempts Tracking (Anti-tamper)
  // ---------------------------------------------------------------------------
  Future<int> getFailedAttempts() async {
    final val = await _storage.read(key: _keyFailedAttempts);
    return int.tryParse(val ?? '0') ?? 0;
  }

  Future<int> getLockoutRemainingSeconds() async {
    final lockedUntilStr = await _storage.read(key: _keyLockedUntil);
    final lastKnownStr = await _storage.read(key: _keyLastKnownTime);

    if (lockedUntilStr == null) return 0;

    final lockedUntil = int.tryParse(lockedUntilStr) ?? 0;
    if (lockedUntil == 0) return 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    final lastKnown = int.tryParse(lastKnownStr ?? '0') ?? now;

    // Detect clock rolled backwards: if now < lastKnown, enforce lockout until lockedUntil
    final effectiveNow = max(now, lastKnown);
    await _storage.write(key: _keyLastKnownTime, value: effectiveNow.toString());

    final diffMs = lockedUntil - effectiveNow;
    if (diffMs <= 0) {
      await _storage.write(key: _keyLockedUntil, value: '0');
      return 0;
    }

    return (diffMs / 1000).ceil();
  }

  /// Calculates progressive lockout duration based on consecutive failures:
  /// 5th fail -> 30s
  /// 6th fail -> 60s
  /// 7th fail -> 300s (5m)
  /// 8+ fail -> 900s (15m)
  static int calculateLockoutSeconds(int failedAttempts) {
    if (failedAttempts < 5) return 0;
    switch (failedAttempts) {
      case 5:
        return 30;
      case 6:
        return 60;
      case 7:
        return 300;
      default:
        return 900;
    }
  }

  Future<int> recordFailedAttempt() async {
    int attempts = await getFailedAttempts();
    attempts += 1;
    await _storage.write(key: _keyFailedAttempts, value: attempts.toString());

    final lockoutDurationSec = calculateLockoutSeconds(attempts);
    if (lockoutDurationSec > 0) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final lockedUntil = now + (lockoutDurationSec * 1000);
      await _storage.write(key: _keyLockedUntil, value: lockedUntil.toString());
      await _storage.write(key: _keyLastKnownTime, value: now.toString());
    }

    return attempts;
  }

  Future<void> resetFailedAttempts() async {
    await _storage.write(key: _keyFailedAttempts, value: '0');
    await _storage.write(key: _keyLockedUntil, value: '0');
  }
}
