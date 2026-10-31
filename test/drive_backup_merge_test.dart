import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:mescheques/database/app_meta_dao.dart';
import 'package:mescheques/database/checks_dao.dart';
import 'package:mescheques/database/database_helper.dart';
import 'package:mescheques/database/images_dao.dart';
import 'package:mescheques/database/persons_dao.dart';
import 'package:mescheques/database/tombstones_dao.dart';
import 'package:mescheques/models/check.dart';
import 'package:mescheques/services/backup_service.dart';
import 'package:mescheques/services/drive_service.dart';
import 'package:mescheques/services/merge_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// --- In-Memory Fake Drive Files Resource for testing ---

class FakeDriveFile {
  final String id;
  String name;
  List<String> parents;
  List<int> bytes;
  bool trashed;

  FakeDriveFile({
    required this.id,
    required this.name,
    required this.parents,
    required this.bytes,
    this.trashed = false,
  });

  String get md5Checksum => 'fake_md5_${bytes.length}';
}

class FakeDriveFilesResource extends Fake implements drive.FilesResource {
  final Map<String, FakeDriveFile> files = {};
  int _idCounter = 1000;

  @override
  Future<drive.File> create(
    drive.File request, {
    bool? enforceSingleParent,
    bool? ignoreDefaultVisibility,
    String? includeLabels,
    String? includePermissionsForView,
    bool? keepRevisionForever,
    String? ocrLanguage,
    bool? supportsAllDrives,
    bool? supportsTeamDrives,
    bool? useContentAsIndexableText,
    String? $fields,
    drive.UploadOptions uploadOptions = drive.UploadOptions.defaultOptions,
    drive.Media? uploadMedia,
  }) async {
    final id = 'drive_file_${++_idCounter}';
    final bytes = <int>[];
    if (uploadMedia != null) {
      await for (final chunk in uploadMedia.stream) {
        bytes.addAll(chunk);
      }
    }

    final fake = FakeDriveFile(
      id: id,
      name: request.name ?? 'unnamed',
      parents: request.parents ?? [],
      bytes: bytes,
    );
    files[id] = fake;

    return drive.File()
      ..id = id
      ..name = fake.name
      ..size = bytes.length.toString()
      ..md5Checksum = fake.md5Checksum
      ..parents = fake.parents;
  }

  @override
  Future<drive.File> update(
    drive.File request,
    String fileId, {
    String? addParents,
    bool? enforceSingleParent,
    String? includeLabels,
    String? includePermissionsForView,
    bool? keepRevisionForever,
    String? ocrLanguage,
    String? removeParents,
    bool? supportsAllDrives,
    bool? supportsTeamDrives,
    bool? useContentAsIndexableText,
    String? $fields,
    drive.UploadOptions uploadOptions = drive.UploadOptions.defaultOptions,
    drive.Media? uploadMedia,
  }) async {
    final existing = files[fileId];
    if (existing == null || existing.trashed) {
      throw drive.DetailedApiRequestError(404, 'File not found');
    }

    if (uploadMedia != null) {
      final bytes = <int>[];
      await for (final chunk in uploadMedia.stream) {
        bytes.addAll(chunk);
      }
      existing.bytes = bytes;
    }
    if (request.name != null) {
      existing.name = request.name!;
    }

    return drive.File()
      ..id = existing.id
      ..name = existing.name
      ..size = existing.bytes.length.toString()
      ..md5Checksum = existing.md5Checksum
      ..parents = existing.parents;
  }

  @override
  Future<Object> get(
    String fileId, {
    bool? acknowledgeAbuse,
    String? includeLabels,
    String? includePermissionsForView,
    bool? supportsAllDrives,
    bool? supportsTeamDrives,
    String? $fields,
    drive.DownloadOptions downloadOptions = drive.DownloadOptions.metadata,
  }) async {
    final existing = files[fileId];
    if (existing == null || existing.trashed) {
      throw drive.DetailedApiRequestError(404, 'File not found');
    }

    if (downloadOptions == drive.DownloadOptions.fullMedia) {
      return drive.Media(Stream.value(existing.bytes), existing.bytes.length);
    }

    return drive.File()
      ..id = existing.id
      ..name = existing.name
      ..size = existing.bytes.length.toString()
      ..md5Checksum = existing.md5Checksum
      ..trashed = existing.trashed
      ..parents = existing.parents;
  }

  @override
  Future<drive.FileList> list({
    String? corpora,
    String? corpus,
    String? driveId,
    bool? includeItemsFromAllDrives,
    String? includeLabels,
    String? includePermissionsForView,
    bool? includeTeamDriveItems,
    String? orderBy,
    int? pageSize,
    String? pageToken,
    String? q,
    String? spaces,
    bool? supportsAllDrives,
    bool? supportsTeamDrives,
    String? teamDriveId,
    String? $fields,
  }) async {
    final matching = <drive.File>[];

    for (final f in files.values) {
      if (f.trashed) continue;
      bool matches = true;

      if (q != null) {
        if (q.contains("name = 'MesCheques'") && f.name != 'MesCheques') {
          matches = false;
        }
        if (q.contains("name = 'images'") && f.name != 'images') {
          matches = false;
        }
        if (q.contains("name = 'backup.mcheques'") && f.name != 'backup.mcheques') {
          matches = false;
        }
        if (q.contains("name = 'backup_previous.mcheques'") && f.name != 'backup_previous.mcheques') {
          matches = false;
        }
        if (q.contains("name = 'manifest.json'") && f.name != 'manifest.json') {
          matches = false;
        }
      }

      if (matches) {
        matching.add(drive.File()
          ..id = f.id
          ..name = f.name
          ..size = f.bytes.length.toString()
          ..md5Checksum = f.md5Checksum
          ..parents = f.parents);
      }
    }

    return drive.FileList()..files = matching;
  }
}

class FakeDriveApi extends Fake implements drive.DriveApi {
  @override
  final FakeDriveFilesResource files = FakeDriveFilesResource();
}

class TestBackupService extends BackupService {
  TestBackupService({super.dbHelper});

  @override
  Future<String> createSafetyBackup() async {
    return '/test/path/safety_backup.json';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late DatabaseHelper dbHelper;
  late ChecksDao checksDao;
  late PersonsDao personsDao;
  late TombstonesDao tombstonesDao;
  late ImagesDao imagesDao;
  late AppMetaDao appMetaDao;
  late BackupService backupService;
  late MergeService mergeService;
  late FakeDriveApi fakeDriveApi;
  late DriveService driveService;

  const testPassword = 'StrongBackupPassword123!';

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    dbHelper = DatabaseHelper.instance;
    dbHelper.setDatabaseForTesting(db);
    await dbHelper.createTablesForTesting(db);

    checksDao = ChecksDao(dbHelper: dbHelper);
    personsDao = PersonsDao(dbHelper: dbHelper);
    tombstonesDao = TombstonesDao(dbHelper: dbHelper);
    imagesDao = ImagesDao(dbHelper: dbHelper);
    appMetaDao = AppMetaDao(dbHelper: dbHelper);
    backupService = TestBackupService(dbHelper: dbHelper);
    mergeService = MergeService(dbHelper: dbHelper, backupService: backupService);

    fakeDriveApi = FakeDriveApi();
    driveService = DriveService(
      driveApi: fakeDriveApi,
      dbHelper: dbHelper,
      appMetaDao: appMetaDao,
      tombstonesDao: tombstonesDao,
      checksDao: checksDao,
      imagesDao: imagesDao,
      backupService: backupService,
      mergeService: mergeService,
    );

    await driveService.saveMasterPassword(testPassword);
  });

  tearDown(() async {
    await db.close();
    dbHelper.setDatabaseForTesting(null);
  });

  test('3 successive backups update the same Drive fileId without creating duplicates', () async {
    final p = await personsDao.findOrCreate('Client Alpha');
    await checksDao.insert(Check(
      uuid: 'check-uuid-1',
      checkNumber: '1001',
      amountCents: 50000,
      checkDate: '2026-08-01',
      receivedDate: '2026-08-01',
      giverId: p.id!,
      createdAt: '2026-08-01T10:00:00',
      updatedAt: '2026-08-01T10:00:00',
    ));

    // Backup 1
    await driveService.uploadBackupSafely(password: testPassword);
    final fileId1 = await appMetaDao.getValue('drive_file_id');
    expect(fileId1, isNotNull);

    // Add another check
    await checksDao.insert(Check(
      uuid: 'check-uuid-2',
      checkNumber: '1002',
      amountCents: 75000,
      checkDate: '2026-08-02',
      receivedDate: '2026-08-02',
      giverId: p.id!,
      createdAt: '2026-08-02T10:00:00',
      updatedAt: '2026-08-02T10:00:00',
    ));

    // Backup 2
    await driveService.uploadBackupSafely(password: testPassword);
    final fileId2 = await appMetaDao.getValue('drive_file_id');
    expect(fileId2, equals(fileId1), reason: 'File ID must be preserved via files.update');

    // Backup 3
    await driveService.uploadBackupSafely(password: testPassword);
    final fileId3 = await appMetaDao.getValue('drive_file_id');
    expect(fileId3, equals(fileId1));

    // Previous backup should also exist (2 versions mode)
    final prevFileId = await appMetaDao.getValue('drive_previous_file_id');
    expect(prevFileId, isNotNull);
    expect(prevFileId, isNot(equals(fileId1)));
  });

  test('Empty database is rejected from overwriting Drive (0 check guard)', () async {
    // Database has 0 checks
    expect(
      () => driveService.uploadBackupSafely(password: testPassword),
      throwsA(isA<DriveEmptyDbException>()),
    );
  });

  test('Drop protection alerts when local checks drop by >= 20% compared to Drive', () async {
    final p = await personsDao.findOrCreate('Client Beta');

    // Insert 10 checks
    for (int i = 1; i <= 10; i++) {
      await checksDao.insert(Check(
        uuid: 'check-uuid-$i',
        checkNumber: '200$i',
        amountCents: 10000,
        checkDate: '2026-08-01',
        receivedDate: '2026-08-01',
        giverId: p.id!,
        createdAt: '2026-08-01T10:00:00',
        updatedAt: '2026-08-01T10:00:00',
      ));
    }

    // First backup to Drive has 10 checks
    await driveService.uploadBackupSafely(password: testPassword);

    // Now delete 4 checks locally (down to 6 checks, which is -40% drop)
    await checksDao.hardDelete(1);
    await checksDao.hardDelete(2);
    await checksDao.hardDelete(3);
    await checksDao.hardDelete(4);

    expect(await checksDao.countAll(), equals(6));

    // Trying to backup without force should throw DriveDropWarningException
    expect(
      () => driveService.uploadBackupSafely(password: testPassword),
      throwsA(isA<DriveDropWarningException>()),
    );

    // With forceIfDrop = true, it succeeds
    await driveService.uploadBackupSafely(password: testPassword, forceIfDrop: true);
    final manifest = await driveService.fetchManifest();
    expect(manifest?.checksCount, equals(6));
  });

  test('Lossless restore: Phone with 10 checks and Drive with 125 checks merges seamlessly into 130 checks', () async {
    final p = await personsDao.findOrCreate('Client Gamma');

    // Build incoming bundle with 125 checks
    final incomingChecks = <Map<String, dynamic>>[];
    for (int i = 1; i <= 125; i++) {
      incomingChecks.add({
        'uuid': 'remote-uuid-$i',
        'check_number': 'REMOTE-$i',
        'amount_cents': 20000,
        'check_date': '2026-08-01',
        'received_date': '2026-08-01',
        'giver_uuid': p.uuid,
        'created_at': '2026-08-01T10:00:00',
        'updated_at': '2026-08-01T10:00:00',
      });
    }

    // 5 checks will share the same UUID between local and remote
    for (int i = 1; i <= 5; i++) {
      await checksDao.insert(Check(
        uuid: 'remote-uuid-$i',
        checkNumber: 'REMOTE-$i',
        amountCents: 20000,
        checkDate: '2026-08-01',
        receivedDate: '2026-08-01',
        giverId: p.id!,
        createdAt: '2026-08-01T10:00:00',
        updatedAt: '2026-08-01T10:00:00',
      ));
    }

    // Plus 5 checks unique to local phone
    for (int i = 1; i <= 5; i++) {
      await checksDao.insert(Check(
        uuid: 'local-only-uuid-$i',
        checkNumber: 'LOCAL-$i',
        amountCents: 15000,
        checkDate: '2026-08-02',
        receivedDate: '2026-08-02',
        giverId: p.id!,
        createdAt: '2026-08-02T10:00:00',
        updatedAt: '2026-08-02T10:00:00',
      ));
    }

    // Local total is 10 checks
    expect(await checksDao.countAll(), equals(10));

    final remotePayload = {
      'application': 'MesCheques',
      'backup_version': 3,
      'db_version': 5,
      'persons': [p.toMap()],
      'checks': incomingChecks,
      'check_images': [],
      'purged_uuids': [],
    };

    final report = await mergeService.analyzeMerge(remotePayload);
    expect(report.newChecksCount, equals(120), reason: '125 remote minus 5 already existing');
    expect(report.identicalChecksCount, equals(5));

    // Apply merge (lossless fusion)
    await mergeService.applyMerge(data: remotePayload, resolvedConflicts: []);

    // Result should be 125 from remote + 5 local-only = 130 checks!
    expect(await checksDao.countAll(), equals(130));

    // Local-only checks must still exist!
    final localOnlyCheck = await checksDao.getByUuid('local-only-uuid-1');
    expect(localOnlyCheck, isNotNull);
    expect(localOnlyCheck?.checkNumber, equals('LOCAL-1'));
  });

  test('Tombstones prevent resurrecting a deleted check when restoring an older backup', () async {
    final p = await personsDao.findOrCreate('Client Delta');

    // Check X was deleted and purged on phone
    final deletedUuid = 'check-to-delete-uuid';
    final deletedCheck = Check(
      uuid: deletedUuid,
      checkNumber: 'CHECK-X',
      amountCents: 30000,
      checkDate: '2026-08-01',
      receivedDate: '2026-08-01',
      giverId: p.id!,
      createdAt: '2026-08-01T10:00:00',
      updatedAt: '2026-08-01T10:00:00',
    );
    await checksDao.insert(deletedCheck);

    // Hard delete check -> automatically records into tombstones table
    await checksDao.hardDelete(1);
    expect(await tombstonesDao.isTombstoned(deletedUuid), isTrue);

    // Now restore an old backup that still contains check X
    final oldBackupPayload = {
      'application': 'MesCheques',
      'backup_version': 3,
      'db_version': 5,
      'persons': [p.toMap()],
      'checks': [deletedCheck.toMap()..['giver_uuid'] = p.uuid],
      'check_images': [],
      'purged_uuids': [],
    };

    final report = await mergeService.analyzeMerge(oldBackupPayload);
    expect(report.newChecksCount, equals(0), reason: 'Tombstone should prevent adding purged check');

    await mergeService.applyMerge(data: oldBackupPayload, resolvedConflicts: []);

    // Check X must NOT have been resurrected
    expect(await checksDao.getByUuid(deletedUuid), isNull);
    expect(await checksDao.countAll(), equals(0));
  });

  test('Manual file deletion on Drive is detected and recreated on next backup', () async {
    final p = await personsDao.findOrCreate('Client Epsilon');
    await checksDao.insert(Check(
      uuid: 'check-123',
      checkNumber: '9999',
      amountCents: 45000,
      checkDate: '2026-08-01',
      receivedDate: '2026-08-01',
      giverId: p.id!,
      createdAt: '2026-08-01T10:00:00',
      updatedAt: '2026-08-01T10:00:00',
    ));

    // First backup creates the file
    await driveService.uploadBackupSafely(password: testPassword);
    final fileId = await appMetaDao.getValue('drive_file_id');
    expect(fileId, isNotNull);

    // Simulate user deleting the file manually on Drive
    fakeDriveApi.files.files.remove(fileId);

    // Next backup detects missing file and recreates it with new ID
    await driveService.uploadBackupSafely(password: testPassword);
    final newFileId = await appMetaDao.getValue('drive_file_id');
    expect(newFileId, isNotNull);
    expect(newFileId, isNot(equals(fileId)));
  });
}
