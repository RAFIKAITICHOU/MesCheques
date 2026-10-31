import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';

class AppMetaDao {
  final DatabaseHelper _dbHelper;

  AppMetaDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<String?> getValue(String key, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final rows = await db.query(
      'app_meta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setValue(String key, String value, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    await db.insert(
      'app_meta',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeKey(String key, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    await db.delete('app_meta', where: 'key = ?', whereArgs: [key]);
  }

  Future<int> getInt(String key, [int defaultValue = 0]) async {
    final v = await getValue(key);
    if (v == null) return defaultValue;
    return int.tryParse(v) ?? defaultValue;
  }

  Future<void> setInt(String key, int value, {Transaction? txn}) async {
    await setValue(key, value.toString(), txn: txn);
  }

  Future<bool> getBool(String key, [bool defaultValue = false]) async {
    final v = await getValue(key);
    if (v == null) return defaultValue;
    return v == 'true';
  }

  Future<void> setBool(String key, bool value, {Transaction? txn}) async {
    await setValue(key, value ? 'true' : 'false', txn: txn);
  }

  // --- Change Tracking ---

  Future<int> incrementChangesCounter({Transaction? txn}) async {
    final current = await getInt('changes_counter', 0);
    final next = current + 1;
    await setInt('changes_counter', next, txn: txn);
    await setValue('last_modified_at', DateTime.now().toIso8601String(), txn: txn);
    return next;
  }

  Future<int> getChangesCounter() async {
    return await getInt('changes_counter', 0);
  }

  Future<void> resetChangesCounter({Transaction? txn}) async {
    await setInt('changes_counter', 0, txn: txn);
  }

  // --- Device Identification ---

  Future<String> getDeviceId() async {
    String? id = await getValue('device_id');
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await setValue('device_id', id);
    }
    return id;
  }

  Future<String> getDeviceName() async {
    String? name = await getValue('device_name');
    if (name == null || name.isEmpty) {
      try {
        name = Platform.localHostname;
        if (name.isEmpty) {
          name = Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iPhone' : 'Appareil');
        }
      } catch (_) {
        name = 'Appareil';
      }
      await setValue('device_name', name);
    }
    return name;
  }

  Future<void> setDeviceName(String name) async {
    await setValue('device_name', name);
  }
}
