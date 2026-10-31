import 'dart:async';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../database/app_meta_dao.dart';
import '../database/checks_dao.dart';
import '../database/database_helper.dart';
import 'drive_service.dart';

enum AutoBackupStatus {
  upToDate,          // ✓ À jour
  waitingConnection, // ⏳ En attente de connexion
  wifiRequired,      // ⏸ Wi-Fi requis
  inProgress,        // 🔄 Sauvegarde en cours...
  failed,            // ⚠ Échec
  dropBlocked,       // ⚠ Baisse de chèques détectée
  conflict,          // ⚠ Conflit
  disabled,          // Sauvegarde automatique désactivée
}

const String autoBackupPeriodicTask = 'mescheques.auto_backup_periodic';
const String autoBackupOneOffTask = 'mescheques.auto_backup_one_off';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final service = AutoBackupService.instance;
      final success = await service.runBackupIfConditionsMet(isBackground: true);
      return success;
    } catch (_) {
      return false;
    }
  });
}

class AutoBackupService extends ChangeNotifier {
  static AutoBackupService? _instance;
  static AutoBackupService get instance => _instance ??= AutoBackupService();

  final DriveService _driveService;
  final AppMetaDao _appMetaDao;
  final ChecksDao _checksDao;
  final Connectivity _connectivity;
  final Battery _battery;

  Timer? _debounceTimer;
  Duration debounceDuration = const Duration(minutes: 2);

  bool _isBackingUp = false;
  bool get isBackingUp => _isBackingUp;

  AutoBackupStatus _status = AutoBackupStatus.disabled;
  AutoBackupStatus get status => _status;

  String? _lastError;
  String? get lastError => _lastError;

  int _imageProgressCurrent = 0;
  int _imageProgressTotal = 0;
  int get imageProgressCurrent => _imageProgressCurrent;
  int get imageProgressTotal => _imageProgressTotal;

  AutoBackupService({
    DriveService? driveService,
    DatabaseHelper? dbHelper,
    AppMetaDao? appMetaDao,
    ChecksDao? checksDao,
    Connectivity? connectivity,
    Battery? battery,
  })  : _driveService = driveService ?? DriveService(),
        _appMetaDao = appMetaDao ?? AppMetaDao(dbHelper: dbHelper),
        _checksDao = checksDao ?? ChecksDao(dbHelper: dbHelper),
        _connectivity = connectivity ?? Connectivity(),
        _battery = battery ?? Battery();

  static void setInstanceForTesting(AutoBackupService? service) {
    _instance = service;
  }

  /// Initialize background worker and initial status
  Future<void> initialize() async {
    try {
      if (!Platform.isLinux && !Platform.isWindows && !kIsWeb) {
        Workmanager().initialize(
          callbackDispatcher,
        );
      }
    } catch (_) {}

    await refreshStatus();
  }

  Future<void> refreshStatus() async {
    final enabled = await _appMetaDao.getBool('auto_backup_enabled', true);
    if (!enabled) {
      _status = AutoBackupStatus.disabled;
      notifyListeners();
      return;
    }

    final signedIn = await _driveService.isSignedIn();
    if (!signedIn) {
      _status = AutoBackupStatus.waitingConnection;
      notifyListeners();
      return;
    }

    final changes = await _appMetaDao.getChangesCounter();
    if (changes == 0) {
      _status = AutoBackupStatus.upToDate;
    } else {
      _status = AutoBackupStatus.waitingConnection;
    }
    notifyListeners();
  }

  /// Called whenever checks or persons are modified
  void onDataChanged() {
    _appMetaDao.incrementChangesCounter().then((_) async {
      final enabled = await _appMetaDao.getBool('auto_backup_enabled', true);
      if (!enabled) return;

      final freq = await _appMetaDao.getValue('auto_backup_frequency') ?? 'after_edit';
      if (freq == 'after_edit') {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(debounceDuration, () {
          runBackupIfConditionsMet();
        });
      }
    }).catchError((_) {});
  }

  /// Checks if conditions are met to run automatic backup
  Future<bool> checkConditions({bool isBackground = false}) async {
    // 1. Google Drive is connected
    final signedIn = await _driveService.isSignedIn();
    if (!signedIn) {
      _status = AutoBackupStatus.waitingConnection;
      notifyListeners();
      return false;
    }

    // 2. Changes since last backup
    final changes = await _appMetaDao.getChangesCounter();
    if (changes == 0) {
      _status = AutoBackupStatus.upToDate;
      notifyListeners();
      return false;
    }

    // 3. Database is not empty
    final count = await _checksDao.countAll();
    if (count == 0) return false;

    // 4. Network available
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      final hasConnection = connectivityResults.any((r) => r != ConnectivityResult.none);
      if (!hasConnection) {
        _status = AutoBackupStatus.waitingConnection;
        notifyListeners();
        return false;
      }

      // Check Wi-Fi only condition for images
      final wifiOnly = await _appMetaDao.getBool('auto_backup_wifi_only', false);
      final hasWifi = connectivityResults.contains(ConnectivityResult.wifi);
      if (wifiOnly && !hasWifi) {
        _status = AutoBackupStatus.wifiRequired;
        notifyListeners();
        return false;
      }
    } catch (_) {}

    // 5. Battery condition (skip if critical < 15% and discharging)
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      if (level < 15 && state == BatteryState.discharging) {
        return false;
      }
    } catch (_) {}

    return true;
  }

  /// Run backup safely if conditions are met
  Future<bool> runBackupIfConditionsMet({
    bool isBackground = false,
    bool forceIfDrop = false,
  }) async {
    if (_isBackingUp) return false;

    final canRun = await checkConditions(isBackground: isBackground);
    if (!canRun) return false;

    return await triggerBackupNow(forceIfDrop: forceIfDrop);
  }

  /// Explicitly trigger a backup (e.g. from "Sauvegarder maintenant" button)
  Future<bool> triggerBackupNow({bool forceIfDrop = false}) async {
    if (_isBackingUp) return false;

    _isBackingUp = true;
    _status = AutoBackupStatus.inProgress;
    _lastError = null;
    _imageProgressCurrent = 0;
    _imageProgressTotal = 0;
    notifyListeners();

    try {
      await _driveService.uploadBackupSafely(
        forceIfDrop: forceIfDrop,
        onImageProgress: (current, total) {
          _imageProgressCurrent = current;
          _imageProgressTotal = total;
          notifyListeners();
        },
      );

      _status = AutoBackupStatus.upToDate;
      _lastError = null;
      notifyListeners();
      return true;
    } on DriveDropWarningException catch (e) {
      _status = AutoBackupStatus.dropBlocked;
      _lastError = e.toString();
      notifyListeners();
      rethrow;
    } on DriveConflictException catch (e) {
      _status = AutoBackupStatus.conflict;
      _lastError = e.toString();
      notifyListeners();
      rethrow;
    } catch (e) {
      _status = AutoBackupStatus.failed;
      _lastError = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
