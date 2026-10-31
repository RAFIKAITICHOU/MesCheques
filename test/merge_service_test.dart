import 'package:flutter_test/flutter_test.dart';
import 'package:mescheques/database/checks_dao.dart';
import 'package:mescheques/database/database_helper.dart';
import 'package:mescheques/database/persons_dao.dart';
import 'package:mescheques/models/check.dart';
import 'package:mescheques/models/check_filter.dart';
import 'package:mescheques/models/merge_report.dart';
import 'package:mescheques/models/person.dart';
import 'package:mescheques/services/backup_service.dart';
import 'package:mescheques/services/merge_service.dart';
import 'package:mescheques/services/transfer_service.dart';
import 'package:mescheques/utils/constants.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

class TestBackupService extends BackupService {
  TestBackupService({super.dbHelper});

  @override
  Future<String> createSafetyBackup() async {
    return '/test/path/safety_backup.json';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('TransferServerInfo tests', () {
    test('generatePin creates a 4-digit PIN', () {
      final pin = TransferService.generatePin();
      expect(pin.length, 4);
      expect(int.tryParse(pin), isNotNull);
    });

    test('toQrString and parseQrString roundtrip', () {
      final info = TransferServerInfo(
        ip: '192.168.1.50',
        port: 8088,
        token: 'secret-token-123',
        pin: '4829',
      );

      final qrStr = info.toQrString();
      expect(qrStr, 'mcheques://192.168.1.50:8088?t=secret-token-123&p=4829');

      final parsed = TransferServerInfo.parseQrString(qrStr);
      expect(parsed, isNotNull);
      expect(parsed!.ip, '192.168.1.50');
      expect(parsed.port, 8088);
      expect(parsed.token, 'secret-token-123');
      expect(parsed.pin, '4829');
    });

    test('parseQrString handles invalid schemes or URLs safely', () {
      expect(TransferServerInfo.parseQrString('https://google.com'), isNull);
      expect(TransferServerInfo.parseQrString('invalid-string'), isNull);
      expect(TransferServerInfo.parseQrString('mcheques://192.168.1.1'), isNull);
    });
  });

  group('MergeService offline synchronization & fusion tests', () {
    late Database db;
    late DatabaseHelper dbHelper;
    late PersonsDao personsDao;
    late ChecksDao checksDao;
    late MergeService mergeService;

    const uuidGen = Uuid();

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      dbHelper.setDatabaseForTesting(db);
      await dbHelper.createTablesForTesting(db);

      personsDao = PersonsDao(dbHelper: dbHelper);
      checksDao = ChecksDao(dbHelper: dbHelper);
      mergeService = MergeService(
        dbHelper: dbHelper,
        personsDao: personsDao,
        checksDao: checksDao,
        backupService: TestBackupService(dbHelper: dbHelper),
      );
    });

    tearDown(() async {
      await db.close();
      dbHelper.setDatabaseForTesting(null);
    });

    test('B is empty: merging incoming data imports persons and checks seamlessly', () async {
      final person1Uuid = uuidGen.v4();
      final person2Uuid = uuidGen.v4();
      final check1Uuid = uuidGen.v4();

      final incomingData = {
        'version': AppConstants.backupVersion,
        'exported_at': '2026-10-30T10:00:00Z',
        'persons': [
          {
            'uuid': person1Uuid,
            'name': 'Société Alpha',
            'created_at': '2026-10-30T09:00:00Z',
          },
          {
            'uuid': person2Uuid,
            'name': 'Fournisseur B',
            'created_at': '2026-10-30T09:05:00Z',
          },
        ],
        'checks': [
          {
            'uuid': check1Uuid,
            'check_number': 'CHQ-1001',
            'amount_cents': 150000,
            'check_date': '2026-11-01',
            'received_date': '2026-10-30',
            'giver_uuid': person1Uuid,
            'paid_to_uuid': person2Uuid,
            'paid_date': '2026-10-30',
            'notes': 'Test check',
            'created_at': '2026-10-30T09:10:00Z',
            'updated_at': '2026-10-30T09:10:00Z',
            'deleted_at': null,
          }
        ],
        'purged_uuids': <String>[],
      };

      final report = await mergeService.analyzeMerge(incomingData);
      expect(report.newChecksCount, 1);
      expect(report.updatedChecksCount, 0);
      expect(report.identicalChecksCount, 0);
      expect(report.newPersonsCount, 2);
      expect(report.hasConflicts, isFalse);

      await mergeService.applyMerge(
        data: incomingData,
        resolvedConflicts: report.conflicts,
      );

      final checks = await checksDao.getChecks(const CheckFilter());
      expect(checks.length, 1);
      expect(checks.first.checkNumber, 'CHQ-1001');
      expect(checks.first.giverName, 'Société Alpha');
      expect(checks.first.paidToName, 'Fournisseur B');
      expect(checks.first.isUsed, isTrue);
    });

    test('Idempotence: merging the exact same payload twice produces 0 duplicates', () async {
      final personUuid = uuidGen.v4();
      final checkUuid = uuidGen.v4();

      final incomingData = {
        'version': AppConstants.backupVersion,
        'exported_at': '2026-10-30T10:00:00Z',
        'persons': [
          {
            'uuid': personUuid,
            'name': 'Client Fidèle',
            'created_at': '2026-10-30T09:00:00Z',
          },
        ],
        'checks': [
          {
            'uuid': checkUuid,
            'check_number': 'CHQ-2002',
            'amount_cents': 350000,
            'check_date': '2026-11-05',
            'received_date': '2026-10-30',
            'giver_uuid': personUuid,
            'paid_to_uuid': null,
            'paid_date': null,
            'notes': 'En stock',
            'created_at': '2026-10-30T09:10:00Z',
            'updated_at': '2026-10-30T09:10:00Z',
            'deleted_at': null,
          }
        ],
        'purged_uuids': <String>[],
      };

      // First merge
      final report1 = await mergeService.analyzeMerge(incomingData);
      expect(report1.newChecksCount, 1);
      await mergeService.applyMerge(
        data: incomingData,
        resolvedConflicts: report1.conflicts,
      );

      // Second merge with same payload
      final report2 = await mergeService.analyzeMerge(incomingData);
      expect(report2.newChecksCount, 0);
      expect(report2.identicalChecksCount, 1);
      expect(report2.newPersonsCount, 0);
      expect(report2.hasConflicts, isFalse);

      await mergeService.applyMerge(
        data: incomingData,
        resolvedConflicts: report2.conflicts,
      );

      // Verify no duplicates created
      final allChecks = await checksDao.getChecks(const CheckFilter());
      expect(allChecks.length, 1);
      final allPersons = await personsDao.getAll();
      expect(allPersons.length, 1);
    });

    test('Updated check: keeps more recent version by updated_at', () async {
      final personUuid = uuidGen.v4();
      final checkUuid = uuidGen.v4();

      final personId = await personsDao.insert(Person(
        uuid: personUuid,
        name: 'Émetteur Existant',
        createdAt: '2026-10-30T08:00:00Z',
      ));

      // Existing check on Phone B
      await checksDao.insert(Check(
        uuid: checkUuid,
        checkNumber: 'CHQ-3003',
        amountCents: 100000,
        checkDate: '2026-11-10',
        receivedDate: '2026-10-30',
        giverId: personId,
        createdAt: '2026-10-30T08:00:00Z',
        updatedAt: '2026-10-30T08:30:00Z',
      ));

      // Incoming check from Phone A with later updated_at and new amount
      final incomingData = {
        'version': AppConstants.backupVersion,
        'exported_at': '2026-10-30T12:00:00Z',
        'persons': [
          {
            'uuid': personUuid,
            'name': 'Émetteur Existant',
            'created_at': '2026-10-30T08:00:00Z',
          },
        ],
        'checks': [
          {
            'uuid': checkUuid,
            'check_number': 'CHQ-3003',
            'amount_cents': 200000, // Updated amount
            'check_date': '2026-11-10',
            'received_date': '2026-10-30',
            'giver_uuid': personUuid,
            'paid_to_uuid': null,
            'paid_date': null,
            'notes': 'Montant ajusté sur A',
            'created_at': '2026-10-30T08:00:00Z',
            'updated_at': '2026-10-30T10:00:00Z', // Newer!
            'deleted_at': null,
          }
        ],
        'purged_uuids': <String>[],
      };

      final report = await mergeService.analyzeMerge(incomingData);
      expect(report.updatedChecksCount, 1);
      expect(report.identicalChecksCount, 0);

      await mergeService.applyMerge(
        data: incomingData,
        resolvedConflicts: report.conflicts,
      );

      final updatedCheck = await checksDao.getByUuid(checkUuid);
      expect(updatedCheck!.amountCents, 200000);
      expect(updatedCheck.notes, 'Montant ajusté sur A');
    });

    test('Conflict detection: same active check number with distinct UUIDs', () async {
      final person1Uuid = uuidGen.v4();
      final checkOnBUuid = uuidGen.v4();

      final personId = await personsDao.insert(Person(
        uuid: person1Uuid,
        name: 'Personne 1',
        createdAt: '2026-10-30T08:00:00Z',
      ));

      // Check on Phone B with number 'CHQ-9999'
      await checksDao.insert(Check(
        uuid: checkOnBUuid,
        checkNumber: 'CHQ-9999',
        amountCents: 50000,
        checkDate: '2026-11-01',
        receivedDate: '2026-10-30',
        giverId: personId,
        createdAt: '2026-10-30T08:00:00Z',
        updatedAt: '2026-10-30T08:00:00Z',
      ));

      // Incoming check from Phone A with DIFFERENT UUID but SAME active number 'CHQ-9999'
      final checkOnAUuid = uuidGen.v4();
      final incomingData = {
        'version': AppConstants.backupVersion,
        'exported_at': '2026-10-30T12:00:00Z',
        'persons': [
          {
            'uuid': person1Uuid,
            'name': 'Personne 1',
            'created_at': '2026-10-30T08:00:00Z',
          },
        ],
        'checks': [
          {
            'uuid': checkOnAUuid,
            'check_number': 'CHQ-9999',
            'amount_cents': 95000,
            'check_date': '2026-11-02',
            'received_date': '2026-10-30',
            'giver_uuid': person1Uuid,
            'paid_to_uuid': null,
            'paid_date': null,
            'notes': 'Different check on A',
            'created_at': '2026-10-30T09:00:00Z',
            'updated_at': '2026-10-30T09:00:00Z',
            'deleted_at': null,
          }
        ],
        'purged_uuids': <String>[],
      };

      final report = await mergeService.analyzeMerge(incomingData);
      expect(report.hasConflicts, isTrue);
      expect(report.conflicts.length, 1);
      expect(report.conflicts.first.incomingCheck.checkNumber, 'CHQ-9999');

      // Test resolution: keepBoth renames incoming so both checks are retained without collision
      report.conflicts.first.resolvedAction = ConflictResolutionAction.keepBoth;

      await mergeService.applyMerge(
        data: incomingData,
        resolvedConflicts: report.conflicts,
      );

      final allChecks = await checksDao.getChecks(const CheckFilter());
      expect(allChecks.length, 2);
      final checkNumbers = allChecks.map((c) => c.checkNumber).toList();
      expect(checkNumbers, contains('CHQ-9999'));
      expect(checkNumbers, contains('CHQ-9999 (transfert)'));
    });

    test('Purged checks: does not resurrect purged checks across devices', () async {
      final personUuid = uuidGen.v4();
      final purgedCheckUuid = uuidGen.v4();

      await personsDao.insert(Person(
        uuid: personUuid,
        name: 'Personne Purge',
        createdAt: '2026-10-30T08:00:00Z',
      ));

      // Record this check as purged in tombstone table on B
      await checksDao.addPurgedCheck(purgedCheckUuid, '2026-10-30T08:00:00Z');

      // Phone A attempts to merge the check (e.g. from an older backup)
      final incomingData = {
        'version': AppConstants.backupVersion,
        'exported_at': '2026-10-30T12:00:00Z',
        'persons': [
          {
            'uuid': personUuid,
            'name': 'Personne Purge',
            'created_at': '2026-10-30T08:00:00Z',
          },
        ],
        'checks': [
          {
            'uuid': purgedCheckUuid,
            'check_number': 'CHQ-PURGED',
            'amount_cents': 500000,
            'check_date': '2026-10-01',
            'received_date': '2026-10-01',
            'giver_uuid': personUuid,
            'paid_to_uuid': null,
            'paid_date': null,
            'created_at': '2026-10-01T08:00:00Z',
            'updated_at': '2026-10-01T08:00:00Z',
            'deleted_at': null,
          }
        ],
        'purged_uuids': <String>[],
      };

      final report = await mergeService.analyzeMerge(incomingData);
      // It should be identified as ignored, not new!
      expect(report.newChecksCount, 0);
      expect(report.hasConflicts, isFalse);

      await mergeService.applyMerge(
        data: incomingData,
        resolvedConflicts: report.conflicts,
      );

      final check = await checksDao.getByUuid(purgedCheckUuid);
      expect(check, isNull); // Never resurrected!
    });

    test('Name normalization across spelling: أحمد matches احمد without duplicate person', () async {
      // B already has 'احمد'
      final personId = await personsDao.insert(Person(
        uuid: uuidGen.v4(),
        name: 'احمد',
        createdAt: '2026-10-30T08:00:00Z',
      ));

      final checkUuid = uuidGen.v4();
      final incomingGiverUuid = uuidGen.v4();

      // A sends check issued by 'أحمد' (with hamza)
      final incomingData = {
        'version': AppConstants.backupVersion,
        'exported_at': '2026-10-30T12:00:00Z',
        'persons': [
          {
            'uuid': incomingGiverUuid,
            'name': 'أحمد',
            'created_at': '2026-10-30T09:00:00Z',
          },
        ],
        'checks': [
          {
            'uuid': checkUuid,
            'check_number': 'CHQ-NORM',
            'amount_cents': 75000,
            'check_date': '2026-11-01',
            'received_date': '2026-10-30',
            'giver_uuid': incomingGiverUuid,
            'paid_to_uuid': null,
            'paid_date': null,
            'created_at': '2026-10-30T09:00:00Z',
            'updated_at': '2026-10-30T09:00:00Z',
            'deleted_at': null,
          }
        ],
        'purged_uuids': <String>[],
      };

      final report = await mergeService.analyzeMerge(incomingData);
      expect(report.newPersonsCount, 0); // Matched by normalized name!

      await mergeService.applyMerge(
        data: incomingData,
        resolvedConflicts: report.conflicts,
      );

      // Verify check is linked to existing person
      final check = await checksDao.getByUuid(checkUuid);
      expect(check!.giverId, personId);

      // Ensure no duplicate person created
      final persons = await personsDao.getAll();
      expect(persons.length, 1);
    });

    test('Mode Replace: wipes current DB and makes B exact replica of A', () async {
      // Existing data on B
      await personsDao.insert(Person(
        uuid: uuidGen.v4(),
        name: 'Ancienne Personne B',
        createdAt: '2026-10-30T08:00:00Z',
      ));

      final personAUuid = uuidGen.v4();
      final checkAUuid = uuidGen.v4();

      final incomingData = {
        'version': AppConstants.backupVersion,
        'exported_at': '2026-10-30T12:00:00Z',
        'persons': [
          {
            'uuid': personAUuid,
            'name': 'Nouvelle Personne A',
            'created_at': '2026-10-30T10:00:00Z',
          },
        ],
        'checks': [
          {
            'uuid': checkAUuid,
            'check_number': 'CHQ-REPLACE',
            'amount_cents': 88000,
            'check_date': '2026-11-15',
            'received_date': '2026-10-30',
            'giver_uuid': personAUuid,
            'paid_to_uuid': null,
            'paid_date': null,
            'created_at': '2026-10-30T10:00:00Z',
            'updated_at': '2026-10-30T10:00:00Z',
            'deleted_at': null,
          }
        ],
        'purged_uuids': <String>[],
      };

      await mergeService.applyReplace(data: incomingData);

      final persons = await personsDao.getAll();
      expect(persons.length, 1);
      expect(persons.first.name, 'Nouvelle Personne A');

      final checks = await checksDao.getChecks(const CheckFilter());
      expect(checks.length, 1);
      expect(checks.first.checkNumber, 'CHQ-REPLACE');
    });
  });
}
