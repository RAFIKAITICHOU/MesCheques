import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../database/app_meta_dao.dart';
import '../database/checks_dao.dart';
import '../database/database_helper.dart';
import '../database/images_dao.dart';
import '../database/tombstones_dao.dart';
import '../models/backup_manifest.dart';
import '../models/merge_report.dart';
import '../utils/constants.dart';
import 'backup_service.dart';
import 'image_service.dart';
import 'merge_service.dart';

class DriveAccountInfo {
  final String email;
  final String? displayName;
  final String? photoUrl;

  DriveAccountInfo({
    required this.email,
    this.displayName,
    this.photoUrl,
  });
}

class DriveDropWarningException implements Exception {
  final int localCount;
  final int remoteCount;

  DriveDropWarningException(this.localCount, this.remoteCount);

  @override
  String toString() =>
      'Cette sauvegarde contient $localCount chèques, celle de Drive en contient $remoteCount. Continuer ?';
}

class DriveEmptyDbException implements Exception {
  @override
  String toString() =>
      'Impossible de sauvegarder : la base de données locale est vide (0 chèque).';
}

class DriveConflictException implements Exception {
  final MergeReport report;

  DriveConflictException(this.report);

  @override
  String toString() =>
      'Conflit détecté lors de la fusion avec les données de Google Drive (${report.conflicts.length} conflit(s)).';
}

class DriveQuotaExceededException implements Exception {
  final String message;
  DriveQuotaExceededException([this.message = 'Espace Google Drive insuffisant.']);

  @override
  String toString() => message;
}

class DriveService {
  final GoogleSignIn _googleSignIn;
  drive.DriveApi? _injectedDriveApi;
  final AppMetaDao _appMetaDao;
  final TombstonesDao _tombstonesDao;
  final ChecksDao _checksDao;
  final ImagesDao _imagesDao;
  final BackupService _backupService;
  final MergeService _mergeService;
  final ImageService _imageService;
  final FlutterSecureStorage _secureStorage;

  static const String _folderName = 'MesCheques';
  static const String _imagesFolderName = 'images';
  static const String _backupFileName = 'backup.mcheques';
  static const String _previousBackupFileName = 'backup_previous.mcheques';
  static const String _manifestFileName = 'manifest.json';

  static const String keyMasterPassword = 'drive_master_password';
  static const String keyMasterKeyHex = 'drive_master_key_hex';
  static const String keyRecoveryCode = 'drive_recovery_code';

  DriveService({
    GoogleSignIn? googleSignIn,
    drive.DriveApi? driveApi,
    DatabaseHelper? dbHelper,
    AppMetaDao? appMetaDao,
    TombstonesDao? tombstonesDao,
    ChecksDao? checksDao,
    ImagesDao? imagesDao,
    BackupService? backupService,
    MergeService? mergeService,
    ImageService? imageService,
    FlutterSecureStorage? secureStorage,
  })  : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: [drive.DriveApi.driveFileScope],
            ),
        _injectedDriveApi = driveApi,
        _appMetaDao = appMetaDao ?? AppMetaDao(dbHelper: dbHelper),
        _tombstonesDao = tombstonesDao ?? TombstonesDao(dbHelper: dbHelper),
        _checksDao = checksDao ?? ChecksDao(dbHelper: dbHelper),
        _imagesDao = imagesDao ?? ImagesDao(dbHelper: dbHelper),
        _backupService = backupService ?? BackupService(dbHelper: dbHelper),
        _mergeService = mergeService ?? MergeService(dbHelper: dbHelper),
        _imageService = imageService ?? ImageService.instance,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // --- Authentication ---

  Future<drive.DriveApi> getDriveApi() async {
    if (_injectedDriveApi != null) return _injectedDriveApi!;

    var client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        throw StateError('Non connecté à Google Drive. Veuillez vous reconnecter.');
      }
      client = await _googleSignIn.authenticatedClient();
      if (client == null) {
        throw StateError('Impossible d\'obtenir une session Google authentifiée.');
      }
    }
    return drive.DriveApi(client);
  }

  void setDriveApiForTesting(drive.DriveApi? api) {
    _injectedDriveApi = api;
  }

  Future<bool> isSignedIn() async {
    if (_injectedDriveApi != null) return true;
    final account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    return account != null;
  }

  Future<DriveAccountInfo?> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    await _appMetaDao.setValue('drive_account_email', account.email);
    if (account.displayName != null) {
      await _appMetaDao.setValue('drive_account_name', account.displayName!);
    }

    return DriveAccountInfo(
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
    );
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _appMetaDao.removeKey('drive_account_email');
    await _appMetaDao.removeKey('drive_account_name');
    _injectedDriveApi = null;
  }

  Future<DriveAccountInfo?> getCurrentUser() async {
    final account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account != null) {
      return DriveAccountInfo(
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
      );
    }
    final email = await _appMetaDao.getValue('drive_account_email');
    if (email != null && email.isNotEmpty) {
      final name = await _appMetaDao.getValue('drive_account_name');
      return DriveAccountInfo(email: email, displayName: name);
    }
    return null;
  }

  // --- Master Key & Password Storage ---

  Future<void> saveMasterPassword(String password) async {
    final salt = BackupService.generateSalt();
    final key = await BackupService.deriveKeyAsync(password, salt);
    final keyHex = key.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    await _secureStorage.write(key: keyMasterPassword, value: password);
    await _secureStorage.write(key: keyMasterKeyHex, value: keyHex);
    await _appMetaDao.setValue('drive_backup_salt', salt);

    // Generate readable recovery code (e.g. ABCD-EFGH-IJKL-MNOP)
    final recoveryCode = _generateRecoveryCode();
    await _secureStorage.write(key: keyRecoveryCode, value: recoveryCode);
  }

  String _generateRecoveryCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer();
    for (int i = 0; i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('-');
      buffer.write(chars[(rnd + i * 37) % chars.length]);
    }
    return buffer.toString();
  }

  Future<String?> getRecoveryCode() async {
    return await _secureStorage.read(key: keyRecoveryCode);
  }

  Future<enc.Key?> getMasterKey() async {
    final keyHex = await _secureStorage.read(key: keyMasterKeyHex);
    if (keyHex != null && keyHex.length == 64) {
      return enc.Key(BackupService.hexToBytes(keyHex));
    }
    final pwd = await _secureStorage.read(key: keyMasterPassword);
    if (pwd != null && pwd.isNotEmpty) {
      final salt = await _appMetaDao.getValue('drive_backup_salt');
      return await BackupService.deriveKeyAsync(pwd, salt);
    }
    return null;
  }

  Future<bool> hasMasterPassword() async {
    final key = await getMasterKey();
    return key != null;
  }

  // --- Folder Management ---

  Future<String> getMesChequesFolderId() async {
    final api = await getDriveApi();
    String? folderId = await _appMetaDao.getValue('drive_folder_id');

    if (folderId != null && folderId.isNotEmpty) {
      try {
        final f = await api.files.get(folderId, $fields: 'id, trashed') as drive.File;
        if (f.trashed != true) return folderId;
      } catch (_) {
        folderId = null;
      }
    }

    // Search existing
    final query = "mimeType = 'application/vnd.google-apps.folder' and name = '$_folderName' and trashed = false";
    final result = await api.files.list(q: query, $fields: 'files(id, name)');
    if (result.files != null && result.files!.isNotEmpty) {
      folderId = result.files!.first.id!;
      await _appMetaDao.setValue('drive_folder_id', folderId);
      return folderId;
    }

    // Create new
    final folder = drive.File()
      ..name = _folderName
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await api.files.create(folder, $fields: 'id');
    folderId = created.id!;
    await _appMetaDao.setValue('drive_folder_id', folderId);
    return folderId;
  }

  Future<String> getImagesFolderId() async {
    final api = await getDriveApi();
    String? imagesFolderId = await _appMetaDao.getValue('drive_images_folder_id');
    final parentFolderId = await getMesChequesFolderId();

    if (imagesFolderId != null && imagesFolderId.isNotEmpty) {
      try {
        final f = await api.files.get(imagesFolderId, $fields: 'id, trashed') as drive.File;
        if (f.trashed != true) return imagesFolderId;
      } catch (_) {
        imagesFolderId = null;
      }
    }

    final query = "mimeType = 'application/vnd.google-apps.folder' and name = '$_imagesFolderName' and '$parentFolderId' in parents and trashed = false";
    final result = await api.files.list(q: query, $fields: 'files(id, name)');
    if (result.files != null && result.files!.isNotEmpty) {
      imagesFolderId = result.files!.first.id!;
      await _appMetaDao.setValue('drive_images_folder_id', imagesFolderId);
      return imagesFolderId;
    }

    final folder = drive.File()
      ..name = _imagesFolderName
      ..parents = [parentFolderId]
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await api.files.create(folder, $fields: 'id');
    imagesFolderId = created.id!;
    await _appMetaDao.setValue('drive_images_folder_id', imagesFolderId);
    return imagesFolderId;
  }

  // --- Manifest Management ---

  Future<BackupManifest?> fetchManifest() async {
    final api = await getDriveApi();
    final parentId = await getMesChequesFolderId();

    final query = "name = '$_manifestFileName' and '$parentId' in parents and trashed = false";
    final result = await api.files.list(q: query, $fields: 'files(id, name)');
    if (result.files == null || result.files!.isEmpty) return null;

    final fileId = result.files!.first.id!;
    await _appMetaDao.setValue('drive_manifest_file_id', fileId);

    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }

    final jsonStr = utf8.decode(bytes);
    return BackupManifest.deserialize(jsonStr);
  }

  Future<String> uploadManifest(BackupManifest manifest) async {
    final api = await getDriveApi();
    final parentId = await getMesChequesFolderId();
    final jsonStr = manifest.serialize();
    final bytes = utf8.encode(jsonStr);

    final media = drive.Media(Stream.value(bytes), bytes.length);
    String? fileId = await _appMetaDao.getValue('drive_manifest_file_id');

    if (fileId != null && fileId.isNotEmpty) {
      try {
        final updated = await api.files.update(
          drive.File(),
          fileId,
          uploadMedia: media,
          $fields: 'id',
        );
        return updated.id!;
      } catch (_) {
        fileId = null;
      }
    }

    // Check if manifest already exists on Drive
    final query = "name = '$_manifestFileName' and '$parentId' in parents and trashed = false";
    final result = await api.files.list(q: query, $fields: 'files(id, name)');
    if (result.files != null && result.files!.isNotEmpty) {
      fileId = result.files!.first.id!;
      final updated = await api.files.update(
        drive.File(),
        fileId,
        uploadMedia: media,
        $fields: 'id',
      );
      await _appMetaDao.setValue('drive_manifest_file_id', updated.id!);
      return updated.id!;
    }

    final newFile = drive.File()
      ..name = _manifestFileName
      ..parents = [parentId];
    final created = await api.files.create(
      newFile,
      uploadMedia: media,
      $fields: 'id',
    );
    await _appMetaDao.setValue('drive_manifest_file_id', created.id!);
    return created.id!;
  }

  // --- Incremental Image Sync ---

  Future<int> syncImagesIncremental({
    enc.Key? key,
    void Function(int current, int total)? onProgress,
  }) async {
    final effectiveKey = key ?? await getMasterKey();
    if (effectiveKey == null) {
      throw StateError('Clé de chiffrement introuvable.');
    }

    final api = await getDriveApi();
    final imagesFolderId = await getImagesFolderId();

    // Query images folder for existing hashes
    final existingImagesOnDrive = <String>{};
    String? pageToken;
    do {
      final list = await api.files.list(
        q: "'$imagesFolderId' in parents and trashed = false",
        $fields: 'nextPageToken, files(name)',
        pageToken: pageToken,
      );
      if (list.files != null) {
        for (final f in list.files!) {
          if (f.name != null && f.name!.endsWith('.img')) {
            final sha = f.name!.replaceAll('.img', '');
            existingImagesOnDrive.add(sha);
          }
        }
      }
      pageToken = list.nextPageToken;
    } while (pageToken != null);

    // List all local images
    final allLocalImages = await _imagesDao.getAllImages();
    final neededUploads = <String, String>{}; // sha256 -> fileName
    for (final img in allLocalImages) {
      if (!existingImagesOnDrive.contains(img.sha256)) {
        neededUploads[img.sha256] = img.fileName;
      }
    }

    final totalToUpload = neededUploads.length;
    if (totalToUpload == 0) return 0;

    int uploadedCount = 0;
    for (final entry in neededUploads.entries) {
      final sha = entry.key;
      final fileName = entry.value;

      try {
        final imgBytes = await _imageService.loadImageBytes(fileName);
        // Encrypt image with backup key before sending to Drive
        final iv = _generateRandomIV();
        final encrypter = enc.Encrypter(enc.AES(effectiveKey, mode: enc.AESMode.cbc));
        final encrypted = encrypter.encryptBytes(imgBytes, iv: iv);

        final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
        combined.setRange(0, iv.bytes.length, iv.bytes);
        combined.setRange(iv.bytes.length, combined.length, encrypted.bytes);

        final media = drive.Media(Stream.value(combined), combined.length);
        final file = drive.File()
          ..name = '$sha.img'
          ..parents = [imagesFolderId];

        await api.files.create(file, uploadMedia: media, $fields: 'id');
        uploadedCount++;
        onProgress?.call(uploadedCount, totalToUpload);
      } catch (_) {
        // Continue uploading remaining images if one fails
      }
    }

    return uploadedCount;
  }

  // --- Safe 4-Step Update with Guardrails ---

  Future<void> uploadBackupSafely({
    bool forceIfDrop = false,
    enc.Key? key,
    String? password,
    void Function(int current, int total)? onImageProgress,
  }) async {
    final effectiveKey = key ??
        (password != null
            ? await BackupService.deriveKeyAsync(
                password,
                await _appMetaDao.getValue('drive_backup_salt'),
              )
            : await getMasterKey());

    if (effectiveKey == null) {
      throw StateError('Mot de passe ou clé de chiffrement non configuré.');
    }

    final api = await getDriveApi();
    final parentFolderId = await getMesChequesFolderId();

    // Guardrail 1: Local database must not be empty
    final localChecksCount = await _checksDao.countAll();
    if (localChecksCount == 0) {
      throw DriveEmptyDbException();
    }

    final deviceId = await _appMetaDao.getDeviceId();
    final deviceName = await _appMetaDao.getDeviceName();

    // Check remote manifest
    final remoteManifest = await fetchManifest();
    if (remoteManifest != null) {
      // Guardrail 2: Drop protection (-20% drop threshold)
      if (!forceIfDrop && remoteManifest.checksCount > 0) {
        final dropThreshold = (remoteManifest.checksCount * 0.8).floor();
        if (localChecksCount < dropThreshold) {
          throw DriveDropWarningException(localChecksCount, remoteManifest.checksCount);
        }
      }

      // Guardrail 3: Multi-device sync before upload (Section 6)
      if (remoteManifest.deviceId.isNotEmpty && remoteManifest.deviceId != deviceId) {
        // Remote file was touched by another device: merge before replacing
        try {
          final remoteBundle = await downloadBackup(key: effectiveKey);
          final mergeReport = await _mergeService.analyzeMerge(remoteBundle.data);
          if (mergeReport.hasConflicts) {
            throw DriveConflictException(mergeReport);
          }
          await _mergeService.applyMerge(
            data: remoteBundle.data,
            resolvedConflicts: [],
          );
        } catch (e) {
          if (e is DriveConflictException) rethrow;
          // If remote backup was unreadable or absent, proceed safely
        }
      }
    }

    // Clean up tombstones older than 90 days before backup
    try {
      await _tombstonesDao.cleanOldTombstones(AppConstants.purgedRetentionDays);
    } catch (_) {}

    // Step 1: Create new backup locally
    final salt = await _appMetaDao.getValue('drive_backup_salt') ?? BackupService.generateSalt();
    final localBackupBytes = await _backupService.encryptPayloadWithKey(
      effectiveKey,
      includeImages: false, // Images are synced incrementally
      deviceId: deviceId,
      deviceName: deviceName,
      saltHex: salt,
    );

    // Step 2: Verify backup locally (decrypt and validate structure)
    await _backupService.verifyBackupIntegrity(
      localBackupBytes,
      key: effectiveKey,
    );

    final localSha256 = sha256.convert(localBackupBytes).toString();

    // Step 3: Backup previous version if 2 versions enabled
    final keepVersions = await _appMetaDao.getInt('auto_backup_keep_versions', 2);
    String? currentFileId = await _appMetaDao.getValue('drive_file_id');

    if (keepVersions == 2) {
      await _rotateToPreviousBackup(api, parentFolderId, currentFileId);
    }

    // Step 4: Upload to Drive (files.update on fixed fileId, or files.create)
    final media = drive.Media(Stream.value(localBackupBytes), localBackupBytes.length);
    drive.File uploadedFile;

    if (currentFileId != null && currentFileId.isNotEmpty) {
      try {
        uploadedFile = await api.files.update(
          drive.File(),
          currentFileId,
          uploadMedia: media,
          $fields: 'id, size, md5Checksum',
        );
      } catch (_) {
        // File was manually deleted on Drive, recreate it
        final newFile = drive.File()
          ..name = _backupFileName
          ..parents = [parentFolderId];
        uploadedFile = await api.files.create(
          newFile,
          uploadMedia: media,
          $fields: 'id, size, md5Checksum',
        );
      }
    } else {
      // Check if file exists by name
      final query = "name = '$_backupFileName' and '$parentFolderId' in parents and trashed = false";
      final res = await api.files.list(q: query, $fields: 'files(id, name)');
      if (res.files != null && res.files!.isNotEmpty) {
        currentFileId = res.files!.first.id!;
        uploadedFile = await api.files.update(
          drive.File(),
          currentFileId,
          uploadMedia: media,
          $fields: 'id, size, md5Checksum',
        );
      } else {
        final newFile = drive.File()
          ..name = _backupFileName
          ..parents = [parentFolderId];
        uploadedFile = await api.files.create(
          newFile,
          uploadMedia: media,
          $fields: 'id, size, md5Checksum',
        );
      }
    }

    await _appMetaDao.setValue('drive_file_id', uploadedFile.id!);

    // Verify upload size
    final remoteSize = int.tryParse(uploadedFile.size ?? '0') ?? 0;
    if (remoteSize > 0 && remoteSize != localBackupBytes.length) {
      throw StateError('Erreur d\'intégrité : la taille du fichier sur Drive ne correspond pas au fichier local.');
    }

    // Incremental images upload
    final includeImages = await _appMetaDao.getBool('auto_backup_include_images', true);
    if (includeImages) {
      await syncImagesIncremental(key: effectiveKey, onProgress: onImageProgress);
    }

    // Update manifest on Drive
    final allImages = await _imagesDao.getAllImages();
    final manifest = BackupManifest(
      deviceId: deviceId,
      deviceName: deviceName,
      createdAt: DateTime.now().toIso8601String(),
      dbVersion: AppConstants.dbVersion,
      backupVersion: AppConstants.backupVersion,
      checksCount: await _checksDao.countAll(),
      imagesCount: allImages.length,
      imagesSha256: allImages.map((i) => i.sha256).toSet().toList(),
      salt: salt,
      checksum: localSha256,
    );
    await uploadManifest(manifest);

    // Save success metadata
    final nowIso = DateTime.now().toIso8601String();
    await _appMetaDao.setValue('last_backup_at', nowIso);
    await _appMetaDao.setInt('last_backup_checks_count', manifest.checksCount);
    await _appMetaDao.setInt('last_backup_images_count', manifest.imagesCount);
    await _appMetaDao.resetChangesCounter();
  }

  Future<void> _rotateToPreviousBackup(
    drive.DriveApi api,
    String parentFolderId,
    String? currentFileId,
  ) async {
    if (currentFileId == null || currentFileId.isEmpty) return;

    try {
      // Download current backup.mcheques
      final media = await api.files.get(
        currentFileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      if (bytes.isEmpty) return;

      final prevMedia = drive.Media(Stream.value(bytes), bytes.length);
      String? prevFileId = await _appMetaDao.getValue('drive_previous_file_id');

      if (prevFileId != null && prevFileId.isNotEmpty) {
        try {
          await api.files.update(
            drive.File(),
            prevFileId,
            uploadMedia: prevMedia,
            $fields: 'id',
          );
          return;
        } catch (_) {
          prevFileId = null;
        }
      }

      // Check if previous backup file exists by name
      final query = "name = '$_previousBackupFileName' and '$parentFolderId' in parents and trashed = false";
      final res = await api.files.list(q: query, $fields: 'files(id, name)');
      if (res.files != null && res.files!.isNotEmpty) {
        prevFileId = res.files!.first.id!;
        await api.files.update(
          drive.File(),
          prevFileId,
          uploadMedia: prevMedia,
          $fields: 'id',
        );
      } else {
        final newFile = drive.File()
          ..name = _previousBackupFileName
          ..parents = [parentFolderId];
        final created = await api.files.create(
          newFile,
          uploadMedia: prevMedia,
          $fields: 'id',
        );
        prevFileId = created.id!;
      }
      await _appMetaDao.setValue('drive_previous_file_id', prevFileId);
    } catch (_) {
      // Rotation failure should not prevent current backup from succeeding
    }
  }

  // --- Download & Restore ---

  Future<BackupRestoreBundle> downloadBackup({
    bool previous = false,
    enc.Key? key,
    String? password,
  }) async {
    final effectiveKey = key ??
        (password != null
            ? await BackupService.deriveKeyAsync(
                password,
                await _appMetaDao.getValue('drive_backup_salt'),
              )
            : await getMasterKey());

    if (effectiveKey == null) {
      throw StateError('Mot de passe ou clé de chiffrement non configuré.');
    }

    final api = await getDriveApi();
    final parentFolderId = await getMesChequesFolderId();
    final targetName = previous ? _previousBackupFileName : _backupFileName;

    final query = "name = '$targetName' and '$parentFolderId' in parents and trashed = false";
    final result = await api.files.list(q: query, $fields: 'files(id, name)');
    if (result.files == null || result.files!.isEmpty) {
      throw StateError('Aucun fichier de sauvegarde trouvé sur Google Drive.');
    }

    final fileId = result.files!.first.id!;
    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }

    final rawBytes = Uint8List.fromList(bytes);
    return await _backupService.verifyBackupIntegrity(rawBytes, key: effectiveKey);
  }

  /// Downloads missing images from Drive images/ folder and writes them to local storage
  Future<int> restoreMissingImagesFromDrive(
    List<Map<String, dynamic>> checkImagesData, {
    enc.Key? key,
  }) async {
    final effectiveKey = key ?? await getMasterKey();
    if (effectiveKey == null) return 0;

    final api = await getDriveApi();
    final imagesFolderId = await getImagesFolderId();

    // Query images on Drive
    final remoteImageFiles = <String, String>{}; // sha256 -> fileId
    String? pageToken;
    do {
      final list = await api.files.list(
        q: "'$imagesFolderId' in parents and trashed = false",
        $fields: 'nextPageToken, files(id, name)',
        pageToken: pageToken,
      );
      if (list.files != null) {
        for (final f in list.files!) {
          if (f.name != null && f.name!.endsWith('.img') && f.id != null) {
            final sha = f.name!.replaceAll('.img', '');
            remoteImageFiles[sha] = f.id!;
          }
        }
      }
      pageToken = list.nextPageToken;
    } while (pageToken != null);

    int restoredCount = 0;
    for (final img in checkImagesData) {
      final sha = img['sha256']?.toString();
      final fileName = img['file_name']?.toString();
      if (sha == null || fileName == null) continue;

      if (!await _imageService.imageExists(fileName) && remoteImageFiles.containsKey(sha)) {
        try {
          final fileId = remoteImageFiles[sha]!;
          final media = await api.files.get(
            fileId,
            downloadOptions: drive.DownloadOptions.fullMedia,
          ) as drive.Media;

          final bytes = <int>[];
          await for (final chunk in media.stream) {
            bytes.addAll(chunk);
          }

          if (bytes.length > 16) {
            final encryptedBytes = Uint8List.fromList(bytes);
            final iv = enc.IV(encryptedBytes.sublist(0, 16));
            final cipher = encryptedBytes.sublist(16);
            final encrypter = enc.Encrypter(enc.AES(effectiveKey, mode: enc.AESMode.cbc));
            final decrypted = encrypter.decryptBytes(enc.Encrypted(cipher), iv: iv);

            await _imageService.restoreImageFromBackup(
              fileName: fileName,
              imageBytes: Uint8List.fromList(decrypted),
            );
            restoredCount++;
          }
        } catch (_) {}
      }
    }

    return restoredCount;
  }

  /// Calculates total size of files inside MesCheques/ folder in bytes
  Future<int> getDriveStorageUsageBytes() async {
    try {
      final api = await getDriveApi();
      final parentFolderId = await getMesChequesFolderId();
      int totalBytes = 0;

      // MesCheques files
      final rootFiles = await api.files.list(
        q: "'$parentFolderId' in parents and trashed = false",
        $fields: 'files(size)',
      );
      if (rootFiles.files != null) {
        for (final f in rootFiles.files!) {
          totalBytes += int.tryParse(f.size ?? '0') ?? 0;
        }
      }

      // images files
      final imagesFolderId = await getImagesFolderId();
      String? pageToken;
      do {
        final imgFiles = await api.files.list(
          q: "'$imagesFolderId' in parents and trashed = false",
          $fields: 'nextPageToken, files(size)',
          pageToken: pageToken,
        );
        if (imgFiles.files != null) {
          for (final f in imgFiles.files!) {
            totalBytes += int.tryParse(f.size ?? '0') ?? 0;
          }
        }
        pageToken = imgFiles.nextPageToken;
      } while (pageToken != null);

      return totalBytes;
    } catch (_) {
      return 0;
    }
  }

  enc.IV _generateRandomIV() {
    final bytes = Uint8List(16);
    final now = DateTime.now().microsecondsSinceEpoch;
    for (int i = 0; i < 16; i++) {
      bytes[i] = ((now >> (i * 4)) ^ (i * 37)) & 0xFF;
    }
    return enc.IV(bytes);
  }
}
