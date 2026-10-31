import '../database/checks_dao.dart';
import '../database/database_helper.dart';
import '../database/images_dao.dart';
import '../database/persons_dao.dart';
import '../models/check.dart';
import '../models/check_image.dart';
import '../models/merge_report.dart';
import '../models/person.dart';
import '../utils/text_normalizer.dart';
import 'backup_service.dart';

class MergeService {
  final DatabaseHelper _dbHelper;
  final PersonsDao _personsDao;
  final ChecksDao _checksDao;
  final ImagesDao _imagesDao;
  final BackupService _backupService;

  MergeService({
    DatabaseHelper? dbHelper,
    PersonsDao? personsDao,
    ChecksDao? checksDao,
    ImagesDao? imagesDao,
    BackupService? backupService,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _personsDao = personsDao ?? PersonsDao(dbHelper: dbHelper),
        _checksDao = checksDao ?? ChecksDao(dbHelper: dbHelper),
        _imagesDao = imagesDao ?? ImagesDao(dbHelper: dbHelper),
        _backupService = backupService ?? BackupService(dbHelper: dbHelper);

  /// Analyze incoming payload against local database and return a preview MergeReport
  Future<MergeReport> analyzeMerge(Map<String, dynamic> data) async {
    final incomingPersons = (data['persons'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final incomingChecks = (data['checks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final incomingPurged = (data['purged_uuids'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final incomingTombstones = (data['tombstones'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final incomingImages = (data['check_images'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // Map incoming persons by uuid and id (for v1 backward compatibility)
    final incomingPersonMap = <String, Map<String, dynamic>>{};
    for (final p in incomingPersons) {
      final uuid = p['uuid']?.toString();
      if (uuid != null) incomingPersonMap[uuid] = p;
      if (p['id'] != null) incomingPersonMap[p['id'].toString()] = p;
    }

    // Load local persons
    final localPersonsList = await _personsDao.getAll();
    final localPersonsByUuid = <String, Person>{
      for (final p in localPersonsList) p.uuid: p,
    };
    final localPersonsByNorm = <String, Person>{
      for (final p in localPersonsList) p.nameNormalized: p,
    };

    // Count new persons
    int newPersonsCount = 0;
    for (final p in incomingPersons) {
      final uuid = p['uuid']?.toString();
      final name = p['name']?.toString() ?? '';
      final norm = TextNormalizer.normalize(name);

      final existsByUuid = uuid != null && localPersonsByUuid.containsKey(uuid);
      final existsByNorm = localPersonsByNorm.containsKey(norm);

      if (!existsByUuid && !existsByNorm) {
        newPersonsCount++;
      }
    }

    // Load local checks and purged / tombstones
    final localChecksList = await _checksDao.getAllRawChecks();
    final localChecksByUuid = <String, Check>{
      for (final c in localChecksList) c.uuid: c,
    };

    final localActiveChecksByNumber = <String, Check>{};
    for (final c in localChecksList) {
      if (c.deletedAt == null) {
        localActiveChecksByNumber[c.checkNumber.trim().toLowerCase()] = c;
      }
    }

    final localPurgedList = await _checksDao.getAllPurgedChecks();
    final localPurgedMap = <String, String>{
      for (final row in localPurgedList)
        row['uuid'].toString(): row['purged_at'].toString(),
    };
    try {
      final db = await _dbHelper.database;
      final localTombstones = await db.query('tombstones');
      for (final row in localTombstones) {
        final u = row['uuid']?.toString();
        final d = row['deleted_at']?.toString();
        if (u != null && d != null) {
          localPurgedMap[u] = d;
        }
      }
    } catch (_) {}

    // Load incoming purged and tombstones map
    final incomingPurgedMap = <String, String>{
      for (final row in incomingPurged)
        row['uuid'].toString(): row['purged_at'].toString(),
    };
    for (final row in incomingTombstones) {
      final u = row['uuid']?.toString();
      final d = row['deleted_at']?.toString();
      if (u != null && d != null) {
        incomingPurgedMap[u] = d;
      }
    }

    // Analyze purged checks propagated to local
    int purgedPropagatedCount = 0;
    for (final entry in incomingPurgedMap.entries) {
      final local = localChecksByUuid[entry.key];
      if (local != null) {
        final purgedAt = entry.value;
        if (local.updatedAt.compareTo(purgedAt) <= 0) {
          purgedPropagatedCount++;
        }
      }
    }

    // Analyze checks
    int newChecksCount = 0;
    int updatedChecksCount = 0;
    int identicalChecksCount = 0;
    final conflicts = <CheckConflict>[];

    int incomingTotalAmount = 0;
    int incomingActiveCount = 0;

    for (final cMap in incomingChecks) {
      final amount = (cMap['amount_cents'] as int?) ?? 0;
      final isDeleted = cMap['deleted_at'] != null;
      if (!isDeleted) {
        incomingTotalAmount += amount;
        incomingActiveCount++;
      }

      final uuid = cMap['uuid']?.toString();
      final checkNumber = (cMap['check_number']?.toString() ?? '').trim();
      final updatedAt = cMap['updated_at']?.toString() ?? '';

      // Check if purged locally
      if (uuid != null && localPurgedMap.containsKey(uuid)) {
        final localPurgedAt = localPurgedMap[uuid]!;
        if (localPurgedAt.compareTo(updatedAt) >= 0) {
          // Check was purged on B after this update on A -> do not resurrect
          continue;
        }
      }

      if (uuid != null && localChecksByUuid.containsKey(uuid)) {
        final local = localChecksByUuid[uuid]!;
        final cmp = updatedAt.compareTo(local.updatedAt);
        if (cmp == 0) {
          identicalChecksCount++;
        } else if (cmp > 0) {
          updatedChecksCount++;
        } else {
          identicalChecksCount++;
        }
      } else {
        // Unknown UUID locally: check for active check_number conflict
        final lowerNumber = checkNumber.toLowerCase();
        final conflictingLocal = localActiveChecksByNumber[lowerNumber];

        if (conflictingLocal != null && conflictingLocal.uuid != uuid) {
          // CONFLICT!
          final incomingCheck = _buildCheckFromMap(cMap);
          final giverUuid = _getGiverUuid(cMap);
          final paidToUuid = _getPaidToUuid(cMap);

          final incomingGiverName = (giverUuid != null && incomingPersonMap.containsKey(giverUuid))
              ? incomingPersonMap[giverUuid]!['name']?.toString() ?? 'Inconnu'
              : 'Inconnu';
          final incomingPaidToName = (paidToUuid != null && incomingPersonMap.containsKey(paidToUuid))
              ? incomingPersonMap[paidToUuid]!['name']?.toString()
              : null;

          final existingWithNames = await _checksDao.getWithNamesByUuid(conflictingLocal.uuid);

          conflicts.add(CheckConflict(
            incomingCheck: incomingCheck,
            incomingGiverName: incomingGiverName,
            incomingPaidToName: incomingPaidToName,
            existingCheck: conflictingLocal,
            existingGiverName: existingWithNames?.giverName ?? 'Inconnu',
            existingPaidToName: existingWithNames?.paidToName,
          ));
        } else {
          newChecksCount++;
        }
      }
    }

    // Analyze incoming images
    final localImages = await _imagesDao.getAllRawImages();
    final localImageUuids = {for (final img in localImages) img.uuid};
    final localImageSha256sByCheckUuid = <String, Set<String>>{};
    for (final img in localImages) {
      final parentCheck = localChecksList.cast<Check?>().firstWhere(
        (c) => c?.id == img.checkId,
        orElse: () => null,
      );
      final checkUuid = parentCheck?.uuid;
      if (checkUuid != null) {
        (localImageSha256sByCheckUuid[checkUuid] ??= {}).add(img.sha256);
      }
    }

    int newImagesCount = 0;
    int incomingImagesSizeBytes = 0;

    for (final img in incomingImages) {
      final imgUuid = img['uuid']?.toString();
      final checkUuid = img['check_uuid']?.toString();
      final sha = img['sha256']?.toString();
      final size = (img['size_bytes'] as int?) ?? 0;

      final isUuidKnown = imgUuid != null && localImageUuids.contains(imgUuid);
      final isShaKnown = checkUuid != null &&
          sha != null &&
          (localImageSha256sByCheckUuid[checkUuid]?.contains(sha) ?? false);

      if (!isUuidKnown && !isShaKnown) {
        newImagesCount++;
        incomingImagesSizeBytes += size;
      }
    }

    final stats = await _checksDao.getStats();

    return MergeReport(
      fileCreatedAt: data['created_at']?.toString(),
      newChecksCount: newChecksCount,
      updatedChecksCount: updatedChecksCount,
      identicalChecksCount: identicalChecksCount,
      newPersonsCount: newPersonsCount,
      purgedPropagatedCount: purgedPropagatedCount,
      conflicts: conflicts,
      incomingChecksTotal: incomingActiveCount,
      incomingAmountCents: incomingTotalAmount,
      currentChecksTotal: stats.totalCount,
      currentAmountCents: stats.totalAmountCents,
      newImagesCount: newImagesCount,
      incomingImagesSizeBytes: incomingImagesSizeBytes,
    );
  }

  /// Apply merge safely within a single SQLite transaction, preceded by safety backup
  Future<void> applyMerge({
    required Map<String, dynamic> data,
    required List<CheckConflict> resolvedConflicts,
    Map<String, dynamic>? incomingImagesBytes,
  }) async {
    // 1. Create automatic safety backup of current data before merging
    await _backupService.createSafetyBackup();

    final db = await _dbHelper.database;

    final incomingPersons = (data['persons'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final incomingChecks = (data['checks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final incomingPurged = (data['purged_uuids'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final incomingImages = (data['check_images'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    await db.transaction((txn) async {
      // -------------------------------------------------------------
      // Step A: Persons merge
      // -------------------------------------------------------------
      final personIdMap = <String, int>{}; // uuid or old id -> local person.id

      for (final pMap in incomingPersons) {
        final uuid = pMap['uuid']?.toString();
        final oldId = pMap['id']?.toString();
        final name = (pMap['name']?.toString() ?? '').trim();
        final norm = TextNormalizer.normalize(name);
        final createdAt = pMap['created_at']?.toString() ?? DateTime.now().toIso8601String();

        Person? matched;
        if (uuid != null) {
          matched = await _personsDao.getByUuid(uuid, txn: txn);
        }
        matched ??= await _personsDao.getByNormalized(norm, txn: txn);

        if (matched != null) {
          if (uuid != null) personIdMap[uuid] = matched.id!;
          if (oldId != null) personIdMap[oldId] = matched.id!;
        } else {
          final newPerson = Person(
            uuid: uuid,
            name: name,
            nameNormalized: norm,
            createdAt: createdAt,
          );
          final newId = await _personsDao.insert(newPerson, txn: txn);
          if (uuid != null) personIdMap[uuid] = newId;
          if (oldId != null) personIdMap[oldId] = newId;
        }
      }

      // -------------------------------------------------------------
      // Step B: Propagate incoming purged UUIDs and tombstones
      // -------------------------------------------------------------
      final allIncomingPurged = <String, String>{};
      for (final pRow in incomingPurged) {
        final uuid = pRow['uuid']?.toString();
        final purgedAt = pRow['purged_at']?.toString();
        if (uuid != null && purgedAt != null) allIncomingPurged[uuid] = purgedAt;
      }
      final incomingTombstones = (data['tombstones'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final tRow in incomingTombstones) {
        final uuid = tRow['uuid']?.toString();
        final deletedAt = tRow['deleted_at']?.toString();
        if (uuid != null && deletedAt != null) allIncomingPurged[uuid] = deletedAt;
      }

      for (final entry in allIncomingPurged.entries) {
        final uuid = entry.key;
        final purgedAt = entry.value;
        await _checksDao.addPurgedCheck(uuid, purgedAt, txn: txn);
        // If B has this check and updated_at <= purgedAt -> delete it permanently
        final localCheck = await _checksDao.getByUuid(uuid, txn: txn);
        if (localCheck != null && localCheck.updatedAt.compareTo(purgedAt) <= 0) {
          await txn.delete('checks', where: 'uuid = ?', whereArgs: [uuid]);
        }
      }

      // -------------------------------------------------------------
      // Step C: Map conflicts resolution
      // -------------------------------------------------------------
      final conflictResolutionMap = <String, CheckConflict>{};
      for (final c in resolvedConflicts) {
        conflictResolutionMap[c.incomingCheck.uuid] = c;
      }

      // Load current local purged checks & tombstones
      final localPurged = await _checksDao.getAllPurgedChecks(txn: txn);
      final localPurgedMap = <String, String>{
        for (final row in localPurged)
          row['uuid'].toString(): row['purged_at'].toString(),
      };
      try {
        final localTombstones = await txn.query('tombstones');
        for (final row in localTombstones) {
          final u = row['uuid']?.toString();
          final d = row['deleted_at']?.toString();
          if (u != null && d != null) {
            localPurgedMap[u] = d;
          }
        }
      } catch (_) {}

      // -------------------------------------------------------------
      // Step D: Merge checks
      // -------------------------------------------------------------
      for (final cMap in incomingChecks) {
        final uuid = cMap['uuid']?.toString();
        var checkNumber = (cMap['check_number']?.toString() ?? '').trim();
        final amountCents = (cMap['amount_cents'] as int?) ?? 0;
        final checkDate = cMap['check_date']?.toString() ?? '';
        final receivedDate = cMap['received_date']?.toString() ?? '';
        final paidDate = cMap['paid_date']?.toString();
        final notes = cMap['notes']?.toString();
        final createdAt = cMap['created_at']?.toString() ?? DateTime.now().toIso8601String();
        final updatedAt = cMap['updated_at']?.toString() ?? DateTime.now().toIso8601String();
        final deletedAt = cMap['deleted_at']?.toString();

        final giverRef = _getGiverUuid(cMap);
        final paidToRef = _getPaidToUuid(cMap);
        final drawerRef = _getDrawerUuid(cMap);

        final giverId = personIdMap[giverRef];
        if (giverId == null) {
          // Cannot insert check without giver
          continue;
        }
        final paidToId = paidToRef != null ? personIdMap[paidToRef] : null;
        final drawerId = drawerRef != null ? personIdMap[drawerRef] : null;

        // Check conflict handling
        if (uuid != null && conflictResolutionMap.containsKey(uuid)) {
          final conflict = conflictResolutionMap[uuid]!;
          switch (conflict.resolvedAction) {
            case ConflictResolutionAction.keepExisting:
              // Keep B, ignore incoming
              continue;
            case ConflictResolutionAction.keepIncoming:
              // Replace B: soft delete existing B check or remove conflict
              final existingId = conflict.existingCheck.id;
              if (existingId != null) {
                await _checksDao.softDelete(existingId, txn: txn);
              }
              break;
            case ConflictResolutionAction.keepBoth:
              // Keep both: rename incoming check number with distinct suffix
              checkNumber = '$checkNumber (transfert)';
              break;
            default:
              break;
          }
        }

        // Check if purged
        if (uuid != null && localPurgedMap.containsKey(uuid)) {
          final localPurgedAt = localPurgedMap[uuid]!;
          if (localPurgedAt.compareTo(updatedAt) >= 0) {
            // Already purged locally, skip
            continue;
          }
        }

        final existingCheck = uuid != null ? await _checksDao.getByUuid(uuid, txn: txn) : null;

        if (existingCheck != null) {
          // Update only if incoming is newer
          if (updatedAt.compareTo(existingCheck.updatedAt) > 0) {
            final updatedCheck = existingCheck.copyWith(
              checkNumber: checkNumber,
              amountCents: amountCents,
              checkDate: checkDate,
              receivedDate: receivedDate,
              giverId: giverId,
              paidToId: () => paidToId,
              drawerId: () => drawerId,
              paidDate: () => paidDate,
              notes: () => notes,
              updatedAt: updatedAt,
              deletedAt: () => deletedAt,
            );
            await _checksDao.update(updatedCheck, txn: txn);
          }
        } else {
          // Insert new check
          final newCheck = Check(
            uuid: uuid,
            checkNumber: checkNumber,
            amountCents: amountCents,
            checkDate: checkDate,
            receivedDate: receivedDate,
            giverId: giverId,
            paidToId: paidToId,
            drawerId: drawerId,
            paidDate: paidDate,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          );
          await _checksDao.insert(newCheck, txn: txn);
        }
      }

      // -------------------------------------------------------------
      // Step E: Merge check images (idempotent duplicate detection)
      // -------------------------------------------------------------
      for (final imgMap in incomingImages) {
        final imgUuid = imgMap['uuid']?.toString();
        final checkRef = imgMap['check_uuid']?.toString() ?? imgMap['check_id']?.toString();
        final sha256 = imgMap['sha256']?.toString();
        final fileName = imgMap['file_name']?.toString();

        if (checkRef == null || sha256 == null || fileName == null) continue;

        // Resolve local check
        final localCheck = await _checksDao.getByUuid(checkRef, txn: txn);
        if (localCheck == null || localCheck.id == null) continue;

        // Check if image exists by UUID
        if (imgUuid != null) {
          final existingByUuid = await _imagesDao.getByUuid(imgUuid, txn: txn);
          if (existingByUuid != null) continue;
        }

        // Check if duplicate sha256 on same check
        final duplicate = await _imagesDao.findDuplicate(localCheck.id!, sha256, txn: txn);
        if (duplicate != null) continue;

        final newImage = CheckImage(
          uuid: imgUuid,
          checkId: localCheck.id!,
          fileName: fileName,
          kind: imgMap['kind']?.toString() ?? 'front',
          sortOrder: (imgMap['sort_order'] as int?) ?? 0,
          sizeBytes: (imgMap['size_bytes'] as int?) ?? 0,
          sha256: sha256,
          createdAt: imgMap['created_at']?.toString() ?? DateTime.now().toIso8601String(),
        );
        await _imagesDao.insert(newImage, txn: txn);
      }
    });
  }

  /// Replace mode: safely wipe and restore incoming data with a safety backup
  Future<void> applyReplace({required Map<String, dynamic> data}) async {
    // 1. Create safety backup first
    await _backupService.createSafetyBackup();

    final db = await _dbHelper.database;
    final incomingPersons = (data['persons'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final incomingChecks = (data['checks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final incomingPurged = (data['purged_uuids'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final incomingImages = (data['check_images'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    await db.transaction((txn) async {
      // Clear current data
      await txn.delete('check_images');
      await txn.delete('checks');
      await txn.delete('persons');
      await txn.delete('purged_checks');

      final personIdMap = <String, int>{};

      for (final pMap in incomingPersons) {
        final uuid = pMap['uuid']?.toString();
        final oldId = pMap['id']?.toString();
        final name = (pMap['name']?.toString() ?? '').trim();
        final norm = (pMap['name_normalized']?.toString()) ?? TextNormalizer.normalize(name);
        final createdAt = pMap['created_at']?.toString() ?? DateTime.now().toIso8601String();

        final p = Person(
          uuid: uuid,
          name: name,
          nameNormalized: norm,
          createdAt: createdAt,
        );
        final newId = await _personsDao.insert(p, txn: txn);
        if (uuid != null) personIdMap[uuid] = newId;
        if (oldId != null) personIdMap[oldId] = newId;
      }

      final checkIdMap = <String, int>{};

      for (final cMap in incomingChecks) {
        final uuid = cMap['uuid']?.toString();
        final checkNumber = (cMap['check_number']?.toString() ?? '').trim();
        final amountCents = (cMap['amount_cents'] as int?) ?? 0;
        final checkDate = cMap['check_date']?.toString() ?? '';
        final receivedDate = cMap['received_date']?.toString() ?? '';
        final paidDate = cMap['paid_date']?.toString();
        final notes = cMap['notes']?.toString();
        final createdAt = cMap['created_at']?.toString() ?? DateTime.now().toIso8601String();
        final updatedAt = cMap['updated_at']?.toString() ?? DateTime.now().toIso8601String();
        final deletedAt = cMap['deleted_at']?.toString();

        final giverRef = _getGiverUuid(cMap);
        final paidToRef = _getPaidToUuid(cMap);
        final drawerRef = _getDrawerUuid(cMap);

        final giverId = personIdMap[giverRef];
        if (giverId == null) continue;
        final paidToId = paidToRef != null ? personIdMap[paidToRef] : null;
        final drawerId = drawerRef != null ? personIdMap[drawerRef] : null;

        final check = Check(
          uuid: uuid,
          checkNumber: checkNumber,
          amountCents: amountCents,
          checkDate: checkDate,
          receivedDate: receivedDate,
          giverId: giverId,
          paidToId: paidToId,
          drawerId: drawerId,
          paidDate: paidDate,
          notes: notes,
          createdAt: createdAt,
          updatedAt: updatedAt,
          deletedAt: deletedAt,
        );
        final newCheckId = await _checksDao.insert(check, txn: txn);
        if (uuid != null) checkIdMap[uuid] = newCheckId;
        if (cMap['id'] != null) checkIdMap[cMap['id'].toString()] = newCheckId;
      }

      for (final imgMap in incomingImages) {
        final checkRef = imgMap['check_uuid']?.toString() ?? imgMap['check_id']?.toString();
        final checkId = checkIdMap[checkRef];
        if (checkId == null) continue;

        final newImage = CheckImage(
          uuid: imgMap['uuid']?.toString(),
          checkId: checkId,
          fileName: imgMap['file_name']?.toString() ?? '',
          kind: imgMap['kind']?.toString() ?? 'front',
          sortOrder: (imgMap['sort_order'] as int?) ?? 0,
          sizeBytes: (imgMap['size_bytes'] as int?) ?? 0,
          sha256: imgMap['sha256']?.toString() ?? '',
          createdAt: imgMap['created_at']?.toString() ?? DateTime.now().toIso8601String(),
        );
        await _imagesDao.insert(newImage, txn: txn);
      }

      for (final pRow in incomingPurged) {
        final uuid = pRow['uuid']?.toString();
        final purgedAt = pRow['purged_at']?.toString();
        if (uuid != null && purgedAt != null) {
          await _checksDao.addPurgedCheck(uuid, purgedAt, txn: txn);
        }
      }
    });
  }

  String? _getGiverUuid(Map<String, dynamic> cMap) {
    if (cMap.containsKey('giver_uuid') && cMap['giver_uuid'] != null) {
      return cMap['giver_uuid'].toString();
    }
    if (cMap.containsKey('giver_id') && cMap['giver_id'] != null) {
      return cMap['giver_id'].toString();
    }
    return null;
  }

  String? _getPaidToUuid(Map<String, dynamic> cMap) {
    if (cMap.containsKey('paid_to_uuid') && cMap['paid_to_uuid'] != null) {
      return cMap['paid_to_uuid'].toString();
    }
    if (cMap.containsKey('paid_to_id') && cMap['paid_to_id'] != null) {
      return cMap['paid_to_id'].toString();
    }
    return null;
  }

  String? _getDrawerUuid(Map<String, dynamic> cMap) {
    if (cMap.containsKey('drawer_uuid') && cMap['drawer_uuid'] != null) {
      return cMap['drawer_uuid'].toString();
    }
    if (cMap.containsKey('drawer_id') && cMap['drawer_id'] != null) {
      return cMap['drawer_id'].toString();
    }
    return null;
  }

  Check _buildCheckFromMap(Map<String, dynamic> map) {
    return Check(
      uuid: map['uuid']?.toString(),
      checkNumber: (map['check_number']?.toString() ?? '').trim(),
      amountCents: (map['amount_cents'] as int?) ?? 0,
      checkDate: map['check_date']?.toString() ?? '',
      receivedDate: map['received_date']?.toString() ?? '',
      giverId: 0,
      paidToId: map['paid_to_id'] != null ? 0 : null,
      drawerId: map['drawer_id'] != null ? 0 : null,
      paidDate: map['paid_date']?.toString(),
      notes: map['notes']?.toString(),
      createdAt: map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
      deletedAt: map['deleted_at']?.toString(),
    );
  }
}
