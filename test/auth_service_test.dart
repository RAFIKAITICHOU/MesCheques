import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mescheques/providers/auth_provider.dart';
import 'package:mescheques/services/auth_service.dart';
import 'package:mescheques/services/biometric_service.dart';

class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _storage.remove(key);
    } else {
      _storage[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.clear();
  }
}

class FakeBiometricService extends Fake implements BiometricService {
  bool available = false;
  bool shouldSucceed = true;

  @override
  Future<bool> canCheckBiometrics() async => available;

  @override
  Future<bool> authenticate({required String localizedReason}) async => shouldSucceed;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService Cryptography & Validation Tests', () {
    test('PBKDF2-HMAC-SHA256 derives 32-byte hash consistently', () {
      final salt = AuthService.generateSalt(16);
      expect(salt.length, 16);

      final hash1 = AuthService.pbkdf2HmacSha256(
        password: '4829',
        salt: salt,
        iterations: 100,
      );
      final hash2 = AuthService.pbkdf2HmacSha256(
        password: '4829',
        salt: salt,
        iterations: 100,
      );
      final hashDiffPassword = AuthService.pbkdf2HmacSha256(
        password: '4830',
        salt: salt,
        iterations: 100,
      );

      expect(hash1.length, 32);
      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(hashDiffPassword)));
    });

    test('Weak PIN detection rejects insecure patterns', () {
      // Too short
      expect(AuthService.validatePinStrength('12'), PinValidationError.tooShort);

      // All identical
      expect(AuthService.validatePinStrength('0000'), PinValidationError.allIdentical);
      expect(AuthService.validatePinStrength('111111'), PinValidationError.allIdentical);
      expect(AuthService.validatePinStrength('9999'), PinValidationError.allIdentical);

      // Sequential ascending
      expect(AuthService.validatePinStrength('1234'), PinValidationError.sequentialAscending);
      expect(AuthService.validatePinStrength('0123'), PinValidationError.sequentialAscending);
      expect(AuthService.validatePinStrength('123456'), PinValidationError.sequentialAscending);
      expect(AuthService.validatePinStrength('4567'), PinValidationError.sequentialAscending);

      // Sequential descending
      expect(AuthService.validatePinStrength('4321'), PinValidationError.sequentialDescending);
      expect(AuthService.validatePinStrength('654321'), PinValidationError.sequentialDescending);
      expect(AuthService.validatePinStrength('9876'), PinValidationError.sequentialDescending);

      // Valid strong PINs
      expect(AuthService.validatePinStrength('4829'), isNull);
      expect(AuthService.validatePinStrength('739182'), isNull);
      expect(AuthService.validatePinStrength('2048'), isNull);
      expect(AuthService.validatePinStrength('198426'), isNull);
    });

    test('Recovery code generation and hashing', () {
      final code = AuthService.generateRecoveryCode();
      // Format: XXXX-XXXX-XXXX
      expect(code.length, 14);
      expect(code.split('-').length, 3);
      for (final chunk in code.split('-')) {
        expect(chunk.length, 4);
      }

      // Case and hyphen insensitivity
      final hash1 = AuthService.hashRecoveryCode(code);
      final hash2 = AuthService.hashRecoveryCode(code.toLowerCase());
      final hash3 = AuthService.hashRecoveryCode(code.replaceAll('-', ''));
      expect(hash1, equals(hash2));
      expect(hash1, equals(hash3));
    });

    test('Progressive lockout calculation matches security rules', () {
      expect(AuthService.calculateLockoutSeconds(1), 0);
      expect(AuthService.calculateLockoutSeconds(4), 0);
      expect(AuthService.calculateLockoutSeconds(5), 30);
      expect(AuthService.calculateLockoutSeconds(6), 60);
      expect(AuthService.calculateLockoutSeconds(7), 300);
      expect(AuthService.calculateLockoutSeconds(8), 900);
      expect(AuthService.calculateLockoutSeconds(12), 900);
    });
  });

  group('AuthService State & Lifecycle Tests', () {
    late FakeSecureStorage storage;
    late AuthService authService;

    setUp(() {
      storage = FakeSecureStorage();
      authService = AuthService(storage: storage);
    });

    test('Initial setup and verification flow', () async {
      expect(await authService.hasPin(), isFalse);

      final recoveryCode = AuthService.generateRecoveryCode();
      await authService.setupPin(
        pin: '5819',
        recoveryCode: recoveryCode,
        enableBiometric: true,
      );

      expect(await authService.hasPin(), isTrue);
      expect(await authService.getPinLength(), 4);
      expect(await authService.isBiometricEnabled(), isTrue);

      // Correct PIN
      expect(await authService.verifyPin('5819'), isTrue);
      // Wrong PIN
      expect(await authService.verifyPin('1234'), isFalse);

      // Verify recovery code
      expect(await authService.verifyRecoveryCode(recoveryCode), isTrue);
      expect(await authService.verifyRecoveryCode('WRONG-CODE-0000'), isFalse);
    });

    test('Changing PIN requires valid old PIN', () async {
      final recoveryCode = AuthService.generateRecoveryCode();
      await authService.setupPin(
        pin: '581920',
        recoveryCode: recoveryCode,
      );

      // Wrong old PIN fails
      final wrongOld = await authService.changePin(oldPin: '000000', newPin: '849201');
      expect(wrongOld, isFalse);
      expect(await authService.verifyPin('581920'), isTrue);

      // Correct old PIN succeeds
      final success = await authService.changePin(oldPin: '581920', newPin: '849201');
      expect(success, isTrue);
      expect(await authService.verifyPin('849201'), isTrue);
      expect(await authService.verifyPin('581920'), isFalse);
    });

    test('Resetting PIN with recovery code', () async {
      final recoveryCode = AuthService.generateRecoveryCode();
      await authService.setupPin(
        pin: '4829',
        recoveryCode: recoveryCode,
      );

      // Reset with valid code
      final ok = await authService.resetPinWithRecoveryCode(
        recoveryCode: recoveryCode.toLowerCase(),
        newPin: '9371',
      );
      expect(ok, isTrue);
      expect(await authService.verifyPin('9371'), isTrue);
      expect(await authService.verifyPin('4829'), isFalse);
    });

    test('Lockout after 5 failed attempts is recorded and maintained', () async {
      final recoveryCode = AuthService.generateRecoveryCode();
      await authService.setupPin(
        pin: '4829',
        recoveryCode: recoveryCode,
      );

      for (int i = 1; i <= 4; i++) {
        final count = await authService.recordFailedAttempt();
        expect(count, i);
        expect(await authService.getLockoutRemainingSeconds(), 0);
      }

      // 5th attempt triggers lockout
      final count5 = await authService.recordFailedAttempt();
      expect(count5, 5);
      final remaining = await authService.getLockoutRemainingSeconds();
      expect(remaining, greaterThan(25));
      expect(remaining, lessThanOrEqualTo(30));

      // Reset on success clears lockout
      await authService.resetFailedAttempts();
      expect(await authService.getFailedAttempts(), 0);
      expect(await authService.getLockoutRemainingSeconds(), 0);
    });
  });

  group('AuthProvider State Management Tests', () {
    late FakeSecureStorage storage;
    late AuthService authService;
    late FakeBiometricService biometricService;
    late AuthProvider authProvider;

    setUp(() async {
      storage = FakeSecureStorage();
      authService = AuthService(storage: storage);
      biometricService = FakeBiometricService();
      authProvider = AuthProvider(
        authService: authService,
        biometricService: biometricService,
      );
      await authProvider.init();
    });

    test('Initial launch requires PIN setup', () {
      expect(authProvider.isInitialized, isTrue);
      expect(authProvider.hasPinSet, isFalse);
      expect(authProvider.isLocked, isFalse); // Waiting for setup
    });

    test('Setup PIN locks app and configures state', () async {
      bool unlockCallbackFired = false;
      authProvider.onAuthenticated = () {
        unlockCallbackFired = true;
      };

      await authProvider.setupPin(
        pin: '4829',
        recoveryCode: AuthService.generateRecoveryCode(),
        enableBiometric: false,
      );

      expect(authProvider.hasPinSet, isTrue);
      expect(authProvider.pinLength, 4);
      expect(authProvider.isLocked, isFalse);
      expect(unlockCallbackFired, isTrue);

      // Now lock app
      authProvider.lockNow();
      expect(authProvider.isLocked, isTrue);

      // Unlock with PIN
      unlockCallbackFired = false;
      final unlocked = await authProvider.unlockWithPin('4829');
      expect(unlocked, isTrue);
      expect(authProvider.isLocked, isFalse);
      expect(unlockCallbackFired, isTrue);
    });

    test('App backgrounding locks according to timeout settings', () async {
      await authProvider.setupPin(
        pin: '4829',
        recoveryCode: AuthService.generateRecoveryCode(),
      );

      // Default timeout = 0 (immediately)
      expect(authProvider.lockTimeoutSeconds, 0);
      authProvider.onAppPaused();
      expect(authProvider.isLocked, isTrue);

      // Unlock
      await authProvider.unlockWithPin('4829');
      expect(authProvider.isLocked, isFalse);

      // Set timeout = 60s
      await authProvider.setLockTimeout(60);
      authProvider.onAppPaused();
      // Should NOT be locked immediately
      expect(authProvider.isLocked, isFalse);

      // Resume immediately (0 seconds elapsed) -> stays unlocked
      authProvider.onAppResumed();
      expect(authProvider.isLocked, isFalse);
    });

    test('Biometric authentication unlocks app', () async {
      biometricService.available = true;
      biometricService.shouldSucceed = true;

      await authProvider.setupPin(
        pin: '4829',
        recoveryCode: AuthService.generateRecoveryCode(),
        enableBiometric: true,
      );

      authProvider.lockNow();
      expect(authProvider.isLocked, isTrue);

      final unlocked = await authProvider.unlockWithBiometric(reason: 'Test');
      expect(unlocked, isTrue);
      expect(authProvider.isLocked, isFalse);
    });
  });
}
