import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mescheques/database/checks_dao.dart';
import 'package:mescheques/database/database_helper.dart';
import 'package:mescheques/database/images_dao.dart';
import 'package:mescheques/database/persons_dao.dart';
import 'package:mescheques/models/check_filter.dart';
import 'package:mescheques/repositories/check_repository.dart';
import 'package:mescheques/repositories/person_repository.dart';
import 'package:mescheques/services/backup_service.dart';
import 'package:mescheques/services/cleanup_service.dart';
import 'package:mescheques/services/image_service.dart';
import 'package:mescheques/services/merge_service.dart';
import 'package:mescheques/services/pdf_service.dart';
import 'package:mescheques/utils/text_normalizer.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

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
    return _data[key];
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
      _data.remove(key);
    } else {
      _data[key] = value;
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
    _data.remove(key);
  }
}

class TestBackupService extends BackupService {
  final Directory tempDir;
  TestBackupService({super.dbHelper, super.imageService, required this.tempDir});

  @override
  Future<String> createSafetyBackup() async {
    final safetyFile = File('${tempDir.path}/test_safety.json');
    await safetyFile.writeAsString('{}', flush: true);
    return safetyFile.path;
  }
}

/// Helper to generate a valid test JPEG image in memory
Uint8List createTestJpeg({int width = 800, int height = 400}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(20, 100, 200));
  return Uint8List.fromList(img.encodeJpg(image, quality: 85));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database db;
  late DatabaseHelper dbHelper;
  late Directory tempDir;
  late FakeSecureStorage fakeStorage;
  late ImageService imageService;
  late PersonsDao personsDao;
  late ChecksDao checksDao;
  late ImagesDao imagesDao;
  late PersonRepository personRepo;
  late CheckRepository checkRepo;
  late CleanupService cleanupService;
  late BackupService backupService;
  late MergeService mergeService;

  setUp(() async {
    final dbFactory = databaseFactoryFfi;
    db = await dbFactory.openDatabase(inMemoryDatabasePath);
    dbHelper = DatabaseHelper.instance;
    dbHelper.setDatabaseForTesting(db);

    // Initialize schema
    await dbHelper.createTablesForTesting(db);

    tempDir = Directory.systemTemp.createTempSync('mescheques_test_');
    fakeStorage = FakeSecureStorage();

    imageService = ImageService(
      storage: fakeStorage,
      storageDir: tempDir,
    );
    ImageService.instance.setStorageDirForTesting(tempDir);

    personsDao = PersonsDao(dbHelper: dbHelper);
    checksDao = ChecksDao(dbHelper: dbHelper);
    imagesDao = ImagesDao(dbHelper: dbHelper);

    personRepo = PersonRepository(dao: personsDao);
    checkRepo = CheckRepository(
      dbHelper: dbHelper,
      checksDao: checksDao,
      personsDao: personsDao,
      imagesDao: imagesDao,
      imageService: imageService,
    );
    cleanupService = CleanupService(
      dbHelper: dbHelper,
      checksDao: checksDao,
      imagesDao: imagesDao,
      imageService: imageService,
    );
    backupService = TestBackupService(
      dbHelper: dbHelper,
      imageService: imageService,
      tempDir: tempDir,
    );
    mergeService = MergeService(
      dbHelper: dbHelper,
      personsDao: personsDao,
      checksDao: checksDao,
      imagesDao: imagesDao,
      backupService: backupService,
    );
  });

  tearDown(() async {
    await db.close();
    dbHelper.setDatabaseForTesting(null);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('1 & 2. Person roles: Titulaire and Donneur', () {
    test('Titulaire = Donneur (identical checkbox checked)', () async {
      final checkId = await checkRepo.createCheck(
        checkNumber: 'CHQ-001',
        amountCents: 250000,
        checkDate: '2026-08-20',
        receivedDate: '2026-08-18',
        giverName: 'Karim Benali',
        drawerName: 'Karim Benali', // Identique au donneur
      );

      final checkWithNames = await checkRepo.getById(checkId);
      expect(checkWithNames, isNotNull);
      expect(checkWithNames!.giverName, 'Karim Benali');
      expect(checkWithNames.drawerName, 'Karim Benali');
      expect(checkWithNames.isDrawerDifferent, isFalse);
    });

    test('Titulaire different from Donneur', () async {
      final checkId = await checkRepo.createCheck(
        checkNumber: 'CHQ-002',
        amountCents: 500000,
        checkDate: '2026-08-22',
        receivedDate: '2026-08-18',
        giverName: 'Karim Benali',
        drawerName: 'Ahmed Ait Ali', // Titulaire distinct
      );

      final checkWithNames = await checkRepo.getById(checkId);
      expect(checkWithNames, isNotNull);
      expect(checkWithNames!.giverName, 'Karim Benali');
      expect(checkWithNames.drawerName, 'Ahmed Ait Ali');
      expect(checkWithNames.isDrawerDifferent, isTrue);
    });

    test('3. Arabic normalization for Titulaire: "أحمد" vs "احمد"', () async {
      // Create drawer with hamza
      final person1 = await personRepo.findOrCreate('أحمد آيت علي');
      // Look up with plain alif
      final person2 = await personRepo.findOrCreate('احمد ايت علي');

      expect(person1.id, equals(person2.id));
      expect(person1.nameNormalized, equals(TextNormalizer.normalize('احمد ايت علي')));

      // Assign to check
      final checkId = await checkRepo.createCheck(
        checkNumber: 'CHQ-003',
        amountCents: 150000,
        checkDate: '2026-08-25',
        receivedDate: '2026-08-19',
        giverName: 'كريم بنعلي',
        drawerName: 'احمد ايت علي',
      );

      // Search check by normalized drawer name
      final results = await checkRepo.query(CheckFilter(searchQuery: 'احمد'));
      expect(results.length, 1);
      expect(results.first.id, checkId);
      expect(results.first.drawerName, 'أحمد آيت علي');
    });
  });

  group('4 & 5. Check images limit, compression & encryption', () {
    test('Image compression downscales large images to max 1600px long edge', () {
      final largeBytes = createTestJpeg(width: 3200, height: 1800);
      expect(largeBytes.length, greaterThan(100000));

      final processed = imageService.compressAndGenerateThumbnail(largeBytes);
      final decodedFull = img.decodeImage(processed.fullBytes)!;

      expect(decodedFull.width, lessThanOrEqualTo(1600));
      expect(decodedFull.height, lessThanOrEqualTo(1600));

      final decodedThumb = img.decodeImage(processed.thumbBytes)!;
      expect(decodedThumb.width, lessThanOrEqualTo(200));
      expect(decodedThumb.height, lessThanOrEqualTo(200));
    });

    test('6. Image files on disk are strongly AES-GCM encrypted (unreadable directly)', () async {
      final jpeg = createTestJpeg(width: 600, height: 400);
      final processed = await imageService.processAndSaveNewImage(rawBytes: jpeg);

      final fullFile = File('${tempDir.path}/${processed.fileName}');
      expect(fullFile.existsSync(), isTrue);

      final diskBytes = fullFile.readAsBytesSync();
      // Raw JPEG magic header is 0xFF 0xD8 0xFF
      final isPlainJpeg = diskBytes.length >= 3 &&
          diskBytes[0] == 0xFF &&
          diskBytes[1] == 0xD8 &&
          diskBytes[2] == 0xFF;
      expect(isPlainJpeg, isFalse, reason: 'Disk file must be encrypted, not plaintext JPEG');

      // Attempting to decode disk bytes directly as image must fail
      final directDecode = img.decodeImage(diskBytes);
      expect(directDecode, isNull);

      // Decrypted via ImageService must succeed and match JPEG magic
      final decrypted = await imageService.loadImageBytes(processed.fileName);
      expect(decrypted[0], 0xFF);
      expect(decrypted[1], 0xD8);
      expect(decrypted[2], 0xFF);
    });

    test('4. Limit of 5 images per check is enforced', () async {
      final checkId = await checkRepo.createCheck(
        checkNumber: 'CHQ-IMG-LIMIT',
        amountCents: 100000,
        checkDate: '2026-08-20',
        receivedDate: '2026-08-18',
        giverName: 'Karim',
      );

      final existing = (await checkRepo.getById(checkId))!;

      final images = <ProcessedImageData>[];
      for (int i = 0; i < 5; i++) {
        final b = createTestJpeg(width: 200 + i * 10, height: 200);
        final proc = await imageService.processAndSaveNewImage(rawBytes: b, sortOrder: i);
        images.add(proc);
      }

      // Add 5 images
      await checkRepo.updateCheck(
        id: checkId,
        checkNumber: existing.checkNumber,
        amountCents: existing.amountCents,
        checkDate: existing.checkDate,
        receivedDate: existing.receivedDate,
        giverName: existing.giverName,
        drawerName: existing.drawerName,
        createdAt: existing.createdAt,
        newImages: images,
      );

      final saved = await checkRepo.getCheckImages(checkId);
      expect(saved.length, 5);

      // Attempting to add 6th image
      final b6 = createTestJpeg(width: 350, height: 200);
      final proc6 = await imageService.processAndSaveNewImage(rawBytes: b6, sortOrder: 5);

      expect(
        () async => await checkRepo.updateCheck(
          id: checkId,
          checkNumber: existing.checkNumber,
          amountCents: existing.amountCents,
          checkDate: existing.checkDate,
          receivedDate: existing.receivedDate,
          giverName: existing.giverName,
          drawerName: existing.drawerName,
          createdAt: existing.createdAt,
          newImages: [proc6],
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Duplicate SHA-256 image detection on same check', () async {
      final jpeg = createTestJpeg(width: 400, height: 300);
      final proc1 = await imageService.processAndSaveNewImage(rawBytes: jpeg);

      final checkId = await checkRepo.createCheck(
        checkNumber: 'CHQ-DUP',
        amountCents: 100000,
        checkDate: '2026-08-20',
        receivedDate: '2026-08-18',
        giverName: 'Karim',
        images: [proc1],
      );

      // Check if duplicate is found
      final duplicate = await imagesDao.findDuplicate(checkId, proc1.sha256);
      expect(duplicate, isNotNull);
      expect(duplicate!.fileName, proc1.fileName);
    });

    test('9. Missing file on disk throws FileSystemException without crashing app', () async {
      final jpeg = createTestJpeg(width: 300, height: 200);
      final proc = await imageService.processAndSaveNewImage(rawBytes: jpeg);

      // Delete file manually from disk
      final file = File('${tempDir.path}/${proc.fileName}');
      file.deleteSync();

      expect(
        () async => await imageService.loadImageBytes(proc.fileName),
        throwsA(isA<FileSystemException>()),
      );
    });
  });

  group('6 & 7. Trash and cleanup operations with images', () {
    test('Soft delete retains images; hard delete removes disk image files', () async {
      final jpeg = createTestJpeg(width: 300, height: 200);
      final proc = await imageService.processAndSaveNewImage(rawBytes: jpeg);

      final checkId = await checkRepo.createCheck(
        checkNumber: 'CHQ-TRASH',
        amountCents: 100000,
        checkDate: '2026-08-20',
        receivedDate: '2026-08-18',
        giverName: 'Karim',
        images: [proc],
      );

      final imageFile = File('${tempDir.path}/${proc.fileName}');
      expect(imageFile.existsSync(), isTrue);

      // Soft delete
      await checkRepo.softDelete(checkId);
      expect(imageFile.existsSync(), isTrue, reason: 'Soft deleted check preserves images on disk');

      // Restore
      await checkRepo.restore(checkId);
      expect(imageFile.existsSync(), isTrue);

      // Hard delete (purge)
      await checkRepo.softDelete(checkId);
      await checkRepo.hardDelete(checkId);

      expect(imageFile.existsSync(), isFalse, reason: 'Hard delete must delete image files from disk');
      final dbRows = await imagesDao.getByCheckId(checkId);
      expect(dbRows.isEmpty, isTrue);
    });

    test('8. Startup orphan file cleanup deletes stray files without database rows', () async {
      final validProc = await imageService.processAndSaveNewImage(rawBytes: createTestJpeg());
      await checkRepo.createCheck(
        checkNumber: 'CHQ-CLEANUP',
        amountCents: 100000,
        checkDate: '2026-08-20',
        receivedDate: '2026-08-18',
        giverName: 'Karim',
        images: [validProc],
      );

      // Create an orphan file on disk with no DB record
      final orphanFile = File('${tempDir.path}/orphan-12345.img');
      orphanFile.writeAsBytesSync([1, 2, 3, 4]);
      expect(orphanFile.existsSync(), isTrue);

      final orphanCount = await cleanupService.run();
      expect(orphanCount, 0); // Cleanup service cleaned 0 checks, but purged orphan files
      expect(orphanFile.existsSync(), isFalse);

      // Valid file must remain
      expect(File('${tempDir.path}/${validProc.fileName}').existsSync(), isTrue);
    });
  });

  group('8 & 9. Backup, Restore & Merge with Images', () {
    test('10 & 11. Backup ZIP with images vs data only, and restore', () async {
      final jpeg = createTestJpeg(width: 400, height: 250);
      final proc = await imageService.processAndSaveNewImage(rawBytes: jpeg);

      final checkId = await checkRepo.createCheck(
        checkNumber: 'CHQ-BACKUP',
        amountCents: 350000,
        checkDate: '2026-08-20',
        receivedDate: '2026-08-18',
        giverName: 'Karim Benali',
        drawerName: 'Ahmed Ait Ali',
        images: [proc],
      );
      expect(checkId, isPositive);

      // 1. Export with images
      final backupWithImagesBytes = await backupService.encryptPayload('pass123', includeImages: true);
      expect(backupWithImagesBytes.length, greaterThan(100));

      final bundleWithImages = await backupService.decryptBackupBundle(
        bytes: backupWithImagesBytes,
        password: 'pass123',
      );
      expect(bundleWithImages.isZipArchive, isTrue);
      expect(bundleWithImages.images.containsKey(proc.fileName), isTrue);

      // 2. Export without images (Data only)
      final backupDataOnlyBytes = await backupService.encryptPayload('pass123', includeImages: false);
      final bundleDataOnly = await backupService.decryptBackupBundle(
        bytes: backupDataOnlyBytes,
        password: 'pass123',
      );
      expect(bundleDataOnly.isZipArchive, isTrue);
      expect(bundleDataOnly.images.isEmpty, isTrue);

      // 3. Test Restore
      final backupFile = File('${tempDir.path}/test_backup.mcheques');
      await backupFile.writeAsBytes(backupWithImagesBytes);

      // Clear disk
      await imageService.deleteImageFiles(proc.fileName);
      expect(File('${tempDir.path}/${proc.fileName}').existsSync(), isFalse);

      await backupService.restoreBackupFromFile(file: backupFile, password: 'pass123');

      // Check restored check
      final restoredChecks = await checkRepo.query(const CheckFilter());
      expect(restoredChecks.length, 1);
      expect(restoredChecks.first.drawerName, 'Ahmed Ait Ali');
      expect(restoredChecks.first.imageCount, 1);

      // Check restored file on disk
      final restoredImages = await imagesDao.getByCheckId(restoredChecks.first.id!);
      expect(restoredImages.length, 1);
      final restoredDiskFile = File('${tempDir.path}/${restoredImages.first.fileName}');
      expect(restoredDiskFile.existsSync(), isTrue);

      final decrypted = await imageService.loadImageBytes(restoredImages.first.fileName);
      expect(decrypted[0], 0xFF);
      expect(decrypted[1], 0xD8);
    });

    test('12 & 13. Merge A ↔ B with check images is idempotent and avoids duplicates', () async {
      final checkId = await checkRepo.createCheck(
        checkNumber: 'CHQ-MERGE',
        amountCents: 200000,
        checkDate: '2026-08-20',
        receivedDate: '2026-08-18',
        giverName: 'Karim Benali',
        drawerName: 'Ahmed Ait Ali',
      );

      final check = (await checkRepo.getById(checkId))!;
      final checkUuid = check.uuid;

      final payload = await backupService.buildExportPayload();

      // Incoming image for this check
      final incomingImageMap = {
        'uuid': 'img-uuid-incoming-1',
        'check_uuid': checkUuid,
        'file_name': 'incoming_test.img',
        'kind': 'front',
        'sort_order': 0,
        'size_bytes': 150000,
        'sha256': 'sha256-dummy-12345',
        'created_at': DateTime.now().toIso8601String(),
      };
      payload['check_images'] = [incomingImageMap];

      // 1. First merge analysis
      final report1 = await mergeService.analyzeMerge(payload);
      expect(report1.newImagesCount, 1);
      expect(report1.incomingImagesSizeBytes, 150000);

      // Apply merge
      await mergeService.applyMerge(data: payload, resolvedConflicts: []);

      final checkImagesAfterMerge = await imagesDao.getByCheckId(checkId);
      expect(checkImagesAfterMerge.length, 1);
      expect(checkImagesAfterMerge.first.uuid, 'img-uuid-incoming-1');

      // 2. Repeated merge with exact same payload
      final report2 = await mergeService.analyzeMerge(payload);
      expect(report2.newImagesCount, 0, reason: 'Idempotent: duplicate images must not be counted as new');

      await mergeService.applyMerge(data: payload, resolvedConflicts: []);
      final checkImagesAfterRepeat = await imagesDao.getByCheckId(checkId);
      expect(checkImagesAfterRepeat.length, 1, reason: 'Duplicate images must not be inserted twice');
    });
  });

  group('10. PDF Export Tests', () {
    test('14. Generate PDF list with Titulaire and single check sheet (Fiche chèque)', () async {
      final checkId = await checkRepo.createCheck(
        checkNumber: 'CHQ-PDF',
        amountCents: 450000,
        checkDate: '2026-08-20',
        receivedDate: '2026-08-18',
        giverName: 'Karim Benali',
        drawerName: 'Ahmed Ait Ali',
      );

      final checkWithNames = (await checkRepo.getById(checkId))!;

      // 1. List PDF in French
      final listPdfFr = await PdfService.generateChecksPdf(
        checks: [checkWithNames],
        filter: const CheckFilter(),
        localeCode: 'fr',
      );
      expect(listPdfFr.length, greaterThan(1000));

      // 2. List PDF in Arabic
      final listPdfAr = await PdfService.generateChecksPdf(
        checks: [checkWithNames],
        filter: const CheckFilter(),
        localeCode: 'ar',
      );
      expect(listPdfAr.length, greaterThan(1000));

      // 3. Fiche chèque with image
      final sampleJpeg = createTestJpeg(width: 400, height: 250);
      final singlePdf = await PdfService.generateSingleCheckPdf(
        check: checkWithNames,
        imageBytes: [sampleJpeg],
        localeCode: 'fr',
      );
      expect(singlePdf.length, greaterThan(1000));
    });
  });
}
