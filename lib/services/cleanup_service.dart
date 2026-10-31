import 'dart:developer' as developer;
import 'dart:io';
import 'package:path/path.dart' as p;
import '../database/checks_dao.dart';
import '../database/database_helper.dart';
import '../database/images_dao.dart';
import '../utils/constants.dart';
import 'image_service.dart';

class CleanupService {
  final ChecksDao _checksDao;
  final ImagesDao _imagesDao;
  final ImageService _imageService;
  final DatabaseHelper _dbHelper;

  CleanupService({
    ChecksDao? checksDao,
    ImagesDao? imagesDao,
    ImageService? imageService,
    DatabaseHelper? dbHelper,
  })  : _checksDao = checksDao ?? ChecksDao(),
        _imagesDao = imagesDao ?? ImagesDao(),
        _imageService = imageService ?? ImageService.instance,
        _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Runs trash cleanup: permanently deletes check images from disk,
  /// deletes checks with deleted_at older than 15 days, purges tombstone records older than 90 days,
  /// and cleans up orphan files on disk.
  Future<int> run() async {
    try {
      final cutoffDate = DateTime.now().subtract(
        const Duration(days: AppConstants.trashRetentionDays),
      );
      final cutoffIso = cutoffDate.toIso8601String();

      // 1. Delete image files from disk for expired checks BEFORE deleting SQL rows
      final db = await _dbHelper.database;
      final expiredChecks = await db.query(
        'checks',
        columns: ['id'],
        where: 'deleted_at IS NOT NULL AND deleted_at < ?',
        whereArgs: [cutoffIso],
      );

      for (final row in expiredChecks) {
        final checkId = row['id'] as int;
        final images = await _imagesDao.getByCheckId(checkId);
        for (final img in images) {
          await _imageService.deleteImageFiles(img.fileName);
        }
      }

      // 2. Perform SQL hard delete for expired checks
      final deletedCount = await _checksDao.cleanupExpiredTrash(cutoffIso);
      if (deletedCount > 0) {
        developer.log(
          'Nettoyage corbeille : $deletedCount chèque(s) expiré(s) supprimé(s) définitivement.',
          name: 'CleanupService',
        );
      }

      // 3. Cleanup tombstone records older than 90 days
      final purgedCleaned = await _checksDao.cleanupOldPurgedRecords(
        AppConstants.purgedRetentionDays,
      );
      if (purgedCleaned > 0) {
        developer.log(
          'Nettoyage tombstones : $purgedCleaned enregistrement(s) purgé(s) ancien(s) retiré(s).',
          name: 'CleanupService',
        );
      }

      // 4. Orphan files cleanup: files on disk without a corresponding row in check_images
      final allDbFileNames = await _imagesDao.getAllFileNames();
      final orphanCount = await _imageService.cleanupOrphanFiles(allDbFileNames);
      if (orphanCount > 0) {
        developer.log(
          'Nettoyage fichiers orphelins : $orphanCount fichier(s) supprimé(s).',
          name: 'CleanupService',
        );
      }

      // 5. Verify integrity: check for database rows pointing to missing disk files
      await _checkMissingFiles(allDbFileNames);

      return deletedCount;
    } catch (e, stack) {
      developer.log('Erreur lors du nettoyage de la corbeille: $e', error: e, stackTrace: stack);
      return 0;
    }
  }

  /// Verifies if any database image row has a missing file on disk
  Future<void> _checkMissingFiles(List<String> fileNames) async {
    try {
      final dir = await _imageService.getImagesDirectory();
      for (final fileName in fileNames) {
        final file = File(p.join(dir.path, fileName));
        if (!await file.exists()) {
          developer.log(
            'Avertissement : le fichier image $fileName référencé en base est introuvable sur le disque.',
            name: 'CleanupService',
          );
        }
      }
    } catch (_) {}
  }

  /// Deletes disk images when emptying trash manually or hard deleting a single check
  Future<void> deleteCheckImagesFiles(int checkId) async {
    final images = await _imagesDao.getByCheckId(checkId);
    for (final img in images) {
      await _imageService.deleteImageFiles(img.fileName);
    }
  }
}
