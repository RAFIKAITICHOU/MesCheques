import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart' as cg;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../services/image_service.dart';
import '../utils/constants.dart';

class BackupRestoreBundle {
  final Map<String, dynamic> data;
  final Map<String, Uint8List> images; // fileName -> decrypted image bytes
  final bool isZipArchive;

  BackupRestoreBundle({
    required this.data,
    required this.images,
    required this.isZipArchive,
  });
}

class BackupService {
  final DatabaseHelper _dbHelper;
  final ImageService _imageService;

  BackupService({DatabaseHelper? dbHelper, ImageService? imageService})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _imageService = imageService ?? ImageService.instance;

  /// Derive a 32-byte (256-bit) AES key from a string password using SHA-256 (synchronous)
  enc.Key _deriveKey(String password) {
    final digest = sha256.convert(utf8.encode(password));
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  /// Derive key using PBKDF2 (100,000 rounds HMAC-SHA256) when salt is given, or SHA-256 otherwise
  static Future<enc.Key> deriveKeyAsync(String password, [String? saltHex]) async {
    if (saltHex != null && saltHex.isNotEmpty) {
      final saltBytes = hexToBytes(saltHex);
      final pbkdf2 = cg.Pbkdf2(
        macAlgorithm: cg.Hmac.sha256(),
        iterations: 100000,
        bits: 256,
      );
      final secretKey = cg.SecretKey(utf8.encode(password));
      final derived = await pbkdf2.deriveKey(
        secretKey: secretKey,
        nonce: saltBytes,
      );
      final bytes = await derived.extractBytes();
      return enc.Key(Uint8List.fromList(bytes));
    }
    final digest = sha256.convert(utf8.encode(password));
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  static String generateSalt() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static Uint8List hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  /// Generates a random 16-byte IV
  enc.IV _generateRandomIV() {
    final rnd = Random.secure();
    final bytes = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      bytes[i] = rnd.nextInt(256);
    }
    return enc.IV(bytes);
  }

  /// Builds the transfer payload Map with universal UUIDs, check_images and purged tombstones
  Future<Map<String, dynamic>> buildExportPayload() async {
    final db = await _dbHelper.database;

    final persons = await db.query('persons', orderBy: 'id ASC');
    final checks = await db.query('checks', orderBy: 'id ASC');
    final purged = await db.query('purged_checks');
    List<Map<String, dynamic>> tombstones = [];
    try {
      tombstones = await db.query('tombstones');
    } catch (_) {}
    final checkImages = await db.query('check_images', orderBy: 'check_id ASC, sort_order ASC');

    // Create person id -> uuid mapping
    final personIdToUuid = <int, String>{};
    for (final p in persons) {
      final id = p['id'] as int;
      final uuid = p['uuid'] as String;
      personIdToUuid[id] = uuid;
    }

    // Create check id -> uuid mapping
    final checkIdToUuid = <int, String>{};
    for (final c in checks) {
      final id = c['id'] as int;
      final uuid = c['uuid'] as String;
      checkIdToUuid[id] = uuid;
    }

    // Map checks to use giver_uuid, paid_to_uuid, and drawer_uuid
    final exportChecks = <Map<String, dynamic>>[];
    for (final c in checks) {
      final cMap = Map<String, dynamic>.from(c);
      final giverId = c['giver_id'] as int?;
      final paidToId = c['paid_to_id'] as int?;
      final drawerId = c['drawer_id'] as int?;

      cMap['giver_uuid'] = giverId != null ? personIdToUuid[giverId] : null;
      cMap['paid_to_uuid'] = paidToId != null ? personIdToUuid[paidToId] : null;
      cMap['drawer_uuid'] = drawerId != null ? personIdToUuid[drawerId] : null;
      exportChecks.add(cMap);
    }

    // Map check_images to use check_uuid
    final exportImages = <Map<String, dynamic>>[];
    for (final img in checkImages) {
      final imgMap = Map<String, dynamic>.from(img);
      final checkId = img['check_id'] as int?;
      imgMap['check_uuid'] = checkId != null ? checkIdToUuid[checkId] : null;
      exportImages.add(imgMap);
    }

    final payload = {
      'application': AppConstants.appName,
      'backup_version': AppConstants.backupVersion,
      'db_version': AppConstants.dbVersion,
      'created_at': DateTime.now().toIso8601String(),
      'persons': persons,
      'checks': exportChecks,
      'check_images': exportImages,
      'purged_uuids': purged,
      'tombstones': tombstones,
    };

    final jsonStr = jsonEncode(payload);
    final checksum = sha256.convert(utf8.encode(jsonStr)).toString();
    payload['checksum'] = checksum;

    return payload;
  }

  /// Encrypts database payload to bytes (ZIP archive encrypted with AES-CBC 256)
  Future<Uint8List> encryptPayload(String password, {bool includeImages = true}) async {
    final payload = await buildExportPayload();
    final exportImages = (payload['check_images'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final archive = Archive();

    final manifest = <String, dynamic>{
      'application': AppConstants.appName,
      'backup_version': AppConstants.backupVersion,
      'db_version': AppConstants.dbVersion,
      'created_at': DateTime.now().toIso8601String(),
      'includes_images': includeImages,
      'persons_count': (payload['persons'] as List).length,
      'checks_count': (payload['checks'] as List).length,
      'images_count': includeImages ? exportImages.length : 0,
      'images_sha256': <String, String>{},
    };

    if (includeImages) {
      for (final img in exportImages) {
        final fileName = img['file_name'] as String?;
        final uuid = img['uuid'] as String?;
        final sha = img['sha256'] as String?;
        if (fileName != null) {
          try {
            final bytes = await _imageService.loadImageBytes(fileName);
            archive.addFile(ArchiveFile('images/$fileName.jpg', bytes.length, bytes));
            if (uuid != null && sha != null) {
              (manifest['images_sha256'] as Map<String, String>)[uuid] = sha;
            }
          } catch (_) {}
        }
      }
    }

    archive.addFile(ArchiveFile.string('manifest.json', jsonEncode(manifest)));
    archive.addFile(ArchiveFile.string('data.json', jsonEncode(payload)));

    final zipBytes = ZipEncoder().encode(archive);

    final key = _deriveKey(password);
    final iv = _generateRandomIV();
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(zipBytes, iv: iv);

    final combinedBytes = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combinedBytes.setRange(0, iv.bytes.length, iv.bytes);
    combinedBytes.setRange(iv.bytes.length, combinedBytes.length, encrypted.bytes);

    return combinedBytes;
  }

  /// Exports database to encrypted .mcheques file and invokes share sheet
  Future<File> createAndShareBackup(String password, {bool includeImages = true}) async {
    final combinedBytes = await encryptPayload(password, includeImages: includeImages);

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final fileName = 'MesCheques_backup_$timestamp.${AppConstants.backupExtension}';
    final filePath = p.join(tempDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(combinedBytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        subject: 'Sauvegarde MesCheques - $timestamp',
        text: 'Sauvegarde chiffrée MesCheques',
      ),
    );

    return file;
  }

  /// Encrypts database payload to bytes using a pre-derived 32-byte key (AES-CBC 256)
  Future<Uint8List> encryptPayloadWithKey(
    enc.Key key, {
    bool includeImages = false,
    String? deviceId,
    String? deviceName,
    String? saltHex,
  }) async {
    final payload = await buildExportPayload();
    if (deviceId != null) payload['device_id'] = deviceId;
    if (deviceName != null) payload['device_name'] = deviceName;

    final exportImages = (payload['check_images'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final archive = Archive();

    final manifest = <String, dynamic>{
      'application': AppConstants.appName,
      'backup_version': AppConstants.backupVersion,
      'db_version': AppConstants.dbVersion,
      'created_at': DateTime.now().toIso8601String(),
      'includes_images': includeImages,
      'persons_count': (payload['persons'] as List).length,
      'checks_count': (payload['checks'] as List).length,
      'images_count': includeImages ? exportImages.length : 0,
      'images_sha256': <String, String>{},
      'device_id': ?deviceId,
      'device_name': ?deviceName,
      'salt': ?saltHex,
    };

    if (includeImages) {
      for (final img in exportImages) {
        final fileName = img['file_name'] as String?;
        final uuid = img['uuid'] as String?;
        final sha = img['sha256'] as String?;
        if (fileName != null) {
          try {
            final bytes = await _imageService.loadImageBytes(fileName);
            archive.addFile(ArchiveFile('images/$fileName.jpg', bytes.length, bytes));
            if (uuid != null && sha != null) {
              (manifest['images_sha256'] as Map<String, String>)[uuid] = sha;
            }
          } catch (_) {}
        }
      }
    }

    archive.addFile(ArchiveFile.string('manifest.json', jsonEncode(manifest)));
    archive.addFile(ArchiveFile.string('data.json', jsonEncode(payload)));

    final zipBytes = ZipEncoder().encode(archive);
    final iv = _generateRandomIV();
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(zipBytes, iv: iv);

    final combinedBytes = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combinedBytes.setRange(0, iv.bytes.length, iv.bytes);
    combinedBytes.setRange(iv.bytes.length, combinedBytes.length, encrypted.bytes);

    return combinedBytes;
  }

  /// Decrypts raw .mcheques bytes into a BackupRestoreBundle using an enc.Key
  Future<BackupRestoreBundle> decryptBackupBundleWithKey({
    required Uint8List bytes,
    required enc.Key key,
  }) async {
    if (bytes.length < 17) {
      throw const FormatException('Fichier de sauvegarde invalide ou corrompu.');
    }

    final ivBytes = bytes.sublist(0, 16);
    final cipherBytes = bytes.sublist(16);

    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    List<int> decryptedBytes;
    try {
      decryptedBytes = encrypter.decryptBytes(enc.Encrypted(cipherBytes), iv: iv);
    } catch (_) {
      throw const FormatException('Mot de passe incorrect ou fichier endommagé.');
    }

    // Check for ZIP magic header PK\x03\x04
    if (decryptedBytes.length >= 4 &&
        decryptedBytes[0] == 0x50 &&
        decryptedBytes[1] == 0x4B &&
        decryptedBytes[2] == 0x03 &&
        decryptedBytes[3] == 0x04) {
      final archive = ZipDecoder().decodeBytes(decryptedBytes);
      Map<String, dynamic>? data;
      final images = <String, Uint8List>{};

      for (final file in archive.files) {
        if (file.name == 'data.json') {
          final contentStr = utf8.decode(file.content as List<int>);
          data = jsonDecode(contentStr) as Map<String, dynamic>;
        } else if (file.name.startsWith('images/')) {
          final rawFileName = file.name.substring('images/'.length);
          final cleanName = rawFileName.endsWith('.jpg')
              ? rawFileName.substring(0, rawFileName.length - 4)
              : rawFileName;
          final imgBytes = Uint8List.fromList(file.content as List<int>);
          images[cleanName] = imgBytes;
        }
      }

      if (data == null) {
        throw const FormatException('Archive de sauvegarde corrompue : data.json manquant.');
      }

      if (data['application'] != AppConstants.appName) {
        throw const FormatException('Ce fichier ne provient pas de l\'application MesCheques.');
      }

      return BackupRestoreBundle(data: data, images: images, isZipArchive: true);
    }

    // Legacy JSON format check (starts with '{' -> 0x7B)
    if (decryptedBytes.isNotEmpty && decryptedBytes[0] == 0x7B) {
      final jsonStr = utf8.decode(decryptedBytes);
      Map<String, dynamic> data;
      try {
        data = jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (_) {
        throw const FormatException('Contenu JSON de sauvegarde non reconnu.');
      }

      if (data['application'] != AppConstants.appName) {
        throw const FormatException('Ce fichier ne provient pas de l\'application MesCheques.');
      }

      return BackupRestoreBundle(data: data, images: const {}, isZipArchive: false);
    }

    throw const FormatException('Format de sauvegarde non reconnu.');
  }

  /// Decrypts raw .mcheques bytes into a BackupRestoreBundle (supporting optional PBKDF2 salt)
  Future<BackupRestoreBundle> decryptBackupBundle({
    required Uint8List bytes,
    required String password,
    String? saltHex,
  }) async {
    final key = await deriveKeyAsync(password, saltHex);
    return decryptBackupBundleWithKey(bytes: bytes, key: key);
  }

  /// Verifies a backup's integrity by attempting to decrypt and validate structure
  Future<BackupRestoreBundle> verifyBackupIntegrity(
    Uint8List bytes, {
    String? password,
    enc.Key? key,
    String? saltHex,
  }) async {
    final effectiveKey = key ?? (password != null ? await deriveKeyAsync(password, saltHex) : null);
    if (effectiveKey == null) {
      throw ArgumentError('Un mot de passe ou une clé est requis pour vérifier la sauvegarde.');
    }
    final bundle = await decryptBackupBundleWithKey(bytes: bytes, key: effectiveKey);
    final data = bundle.data;
    if (data['application'] != AppConstants.appName) {
      throw const FormatException('Ce fichier ne provient pas de l\'application MesCheques.');
    }
    if (data['checks'] == null || data['persons'] == null) {
      throw const FormatException('Données de sauvegarde incomplètes.');
    }
    return bundle;
  }

  /// Decrypts raw .mcheques bytes with password, validates checksum and structure (backward compatibility)
  Map<String, dynamic> decryptPayloadBytes({
    required Uint8List bytes,
    required String password,
  }) {
    if (bytes.length < 17) {
      throw const FormatException('Fichier de sauvegarde invalide ou corrompu.');
    }

    final ivBytes = bytes.sublist(0, 16);
    final cipherBytes = bytes.sublist(16);

    final iv = enc.IV(ivBytes);
    final key = _deriveKey(password);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    List<int> decryptedBytes;
    try {
      decryptedBytes = encrypter.decryptBytes(enc.Encrypted(cipherBytes), iv: iv);
    } catch (_) {
      throw const FormatException('Mot de passe incorrect ou fichier endommagé.');
    }

    // Check for ZIP magic header PK\x03\x04
    if (decryptedBytes.length >= 4 &&
        decryptedBytes[0] == 0x50 &&
        decryptedBytes[1] == 0x4B &&
        decryptedBytes[2] == 0x03 &&
        decryptedBytes[3] == 0x04) {
      final archive = ZipDecoder().decodeBytes(decryptedBytes);
      for (final file in archive.files) {
        if (file.name == 'data.json') {
          final contentStr = utf8.decode(file.content as List<int>);
          final data = jsonDecode(contentStr) as Map<String, dynamic>;
          if (data['application'] != AppConstants.appName) {
            throw const FormatException('Ce fichier ne provient pas de l\'application MesCheques.');
          }
          return data;
        }
      }
      throw const FormatException('Archive de sauvegarde corrompue : data.json manquant.');
    }

    // Legacy JSON
    final jsonStr = utf8.decode(decryptedBytes);
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    if (data['application'] != AppConstants.appName) {
      throw const FormatException('Ce fichier ne provient pas de l\'application MesCheques.');
    }
    return data;
  }

  /// Decrypts a File into data Map
  Future<Map<String, dynamic>> decryptFile({
    required File file,
    required String password,
  }) async {
    final bytes = await file.readAsBytes();
    return decryptPayloadBytes(bytes: bytes, password: password);
  }

  /// Automatically creates an internal safety backup in application documents before restore or merge
  Future<String> createSafetyBackup() async {
    final payload = await buildExportPayload();
    final appDocDir = await getApplicationDocumentsDirectory();
    final safetyDir = Directory(p.join(appDocDir.path, 'safety_backups'));
    if (!await safetyDir.exists()) {
      await safetyDir.create(recursive: true);
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final safetyFile = File(p.join(safetyDir.path, 'safety_$ts.json'));
    await safetyFile.writeAsString(jsonEncode(payload), flush: true);
    return safetyFile.path;
  }

  /// Restores backup from file in replace mode (rebuilding database and re-encrypting image files)
  Future<void> restoreBackupFromFile({
    required File file,
    required String password,
  }) async {
    final bytes = await file.readAsBytes();
    final bundle = await decryptBackupBundle(bytes: bytes, password: password);
    await replaceDatabase(bundle);
  }

  /// Restores database in replace mode directly from an in-memory BackupRestoreBundle
  Future<void> replaceDatabase(BackupRestoreBundle bundle) async {
    final data = bundle.data;

    final persons = (data['persons'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final checks = (data['checks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final checkImages = (data['check_images'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final purged = (data['purged_uuids'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    await createSafetyBackup();

    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('check_images');
      await txn.delete('checks');
      await txn.delete('persons');
      await txn.delete('purged_checks');
      await txn.delete('tombstones');

      final personIdMap = <dynamic, int>{};

      for (final p in persons) {
        final newId = await txn.insert('persons', {
          'uuid': p['uuid'],
          'name': p['name'],
          'name_normalized': p['name_normalized'],
          'created_at': p['created_at'],
        });
        if (p['uuid'] != null) personIdMap[p['uuid']] = newId;
        if (p['id'] != null) personIdMap[p['id']] = newId;
      }

      final checkIdMap = <dynamic, int>{};

      for (final c in checks) {
        final giverRef = c['giver_uuid'] ?? c['giver_id'];
        final paidToRef = c['paid_to_uuid'] ?? c['paid_to_id'];
        final drawerRef = c['drawer_uuid'] ?? c['drawer_id'];

        final giverId = personIdMap[giverRef];
        if (giverId == null) continue;
        final paidToId = paidToRef != null ? personIdMap[paidToRef] : null;
        final drawerId = drawerRef != null ? personIdMap[drawerRef] : null;

        final newCheckId = await txn.insert('checks', {
          'uuid': c['uuid'],
          'check_number': c['check_number'],
          'amount_cents': c['amount_cents'],
          'check_date': c['check_date'],
          'received_date': c['received_date'],
          'giver_id': giverId,
          'paid_to_id': paidToId,
          'drawer_id': drawerId,
          'paid_date': c['paid_date'],
          'notes': c['notes'],
          'search_text': c['search_text'],
          'created_at': c['created_at'],
          'updated_at': c['updated_at'],
          'deleted_at': c['deleted_at'],
        });

        if (c['uuid'] != null) checkIdMap[c['uuid']] = newCheckId;
        if (c['id'] != null) checkIdMap[c['id']] = newCheckId;
      }

      for (final img in checkImages) {
        final checkRef = img['check_uuid'] ?? img['check_id'];
        final checkId = checkIdMap[checkRef];
        if (checkId == null) continue;

        await txn.insert('check_images', {
          'uuid': img['uuid'],
          'check_id': checkId,
          'file_name': img['file_name'],
          'kind': img['kind'] ?? 'front',
          'sort_order': img['sort_order'] ?? 0,
          'size_bytes': img['size_bytes'] ?? 0,
          'sha256': img['sha256'],
          'created_at': img['created_at'] ?? DateTime.now().toIso8601String(),
        });
      }

      final tombstones = (data['tombstones'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final t in tombstones) {
        final uuid = t['uuid']?.toString();
        final entityType = t['entity_type']?.toString() ?? 'check';
        final deletedAt = t['deleted_at']?.toString();
        if (uuid != null && deletedAt != null) {
          await txn.insert('tombstones', {
            'uuid': uuid,
            'entity_type': entityType,
            'deleted_at': deletedAt,
          });
        }
      }

      for (final pRow in purged) {
        final uuid = pRow['uuid']?.toString();
        final purgedAt = pRow['purged_at']?.toString();
        if (uuid != null && purgedAt != null) {
          await txn.insert('purged_checks', {
            'uuid': uuid,
            'purged_at': purgedAt,
          });
          await txn.insert(
            'tombstones',
            {
              'uuid': uuid,
              'entity_type': 'check',
              'deleted_at': purgedAt,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    });

    // Write any restored images to disk with local device encryption
    for (final entry in bundle.images.entries) {
      await _imageService.restoreImageFromBackup(
        fileName: entry.key,
        imageBytes: entry.value,
      );
    }
  }

  /// File picker helper
  Future<File?> pickBackupFile() async {
    final PlatformFile? file = await FilePicker.pickFile();
    if (file?.path != null) {
      return File(file!.path!);
    }
    return null;
  }
}
