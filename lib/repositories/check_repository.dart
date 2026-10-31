import '../database/database_helper.dart';
import '../database/checks_dao.dart';
import '../database/images_dao.dart';
import '../database/persons_dao.dart';
import '../models/check.dart';
import '../models/check_filter.dart';
import '../models/check_image.dart';
import '../models/person.dart';
import '../services/image_service.dart';
import '../utils/constants.dart';

class CheckRepository {
  final DatabaseHelper _dbHelper;
  final ChecksDao _checksDao;
  final PersonsDao _personsDao;
  final ImagesDao _imagesDao;
  final ImageService _imageService;

  CheckRepository({
    DatabaseHelper? dbHelper,
    ChecksDao? checksDao,
    PersonsDao? personsDao,
    ImagesDao? imagesDao,
    ImageService? imageService,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _checksDao = checksDao ?? ChecksDao(dbHelper: dbHelper),
        _personsDao = personsDao ?? PersonsDao(dbHelper: dbHelper),
        _imagesDao = imagesDao ?? ImagesDao(dbHelper: dbHelper),
        _imageService = imageService ?? ImageService.instance;

  /// Check if a check number is already taken by an active check
  Future<bool> isCheckNumberTaken(String checkNumber, {int? excludeId}) {
    return _checksDao.existsNumber(checkNumber, excludeId: excludeId);
  }

  /// Create a new check with automatic find-or-create for persons and images in a single transaction
  Future<int> createCheck({
    required String checkNumber,
    required int amountCents,
    required String checkDate,
    required String receivedDate,
    required String giverName,
    String? drawerName,
    String? paidToName,
    String? paidDate,
    String? notes,
    List<ProcessedImageData>? images,
  }) async {
    final db = await _dbHelper.database;

    // Check duplicate check number first
    final exists = await _checksDao.existsNumber(checkNumber);
    if (exists) {
      throw StateError('Le numéro de chèque "$checkNumber" existe déjà.');
    }

    if (images != null && images.length > AppConstants.maxImagesPerCheck) {
      throw StateError('Maximum ${AppConstants.maxImagesPerCheck} images autorisées par chèque.');
    }

    return await db.transaction<int>((txn) async {
      // Find or create giver
      final giver = await _personsDao.findOrCreate(giverName, txn: txn);

      // Find or create drawer if provided
      Person? drawer;
      if (drawerName != null && drawerName.trim().isNotEmpty) {
        drawer = await _personsDao.findOrCreate(drawerName, txn: txn);
      }

      // Find or create paid_to if provided
      Person? paidTo;
      if (paidToName != null && paidToName.trim().isNotEmpty) {
        paidTo = await _personsDao.findOrCreate(paidToName, txn: txn);
      }

      final nowIso = DateTime.now().toIso8601String();
      final check = Check(
        checkNumber: checkNumber.trim(),
        amountCents: amountCents,
        checkDate: checkDate,
        receivedDate: receivedDate,
        giverId: giver.id!,
        drawerId: drawer?.id,
        paidToId: paidTo?.id,
        paidDate: paidTo != null ? paidDate : null,
        notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
        createdAt: nowIso,
        updatedAt: nowIso,
      );

      final checkId = await _checksDao.insert(check, txn: txn);

      // Associate images if any
      if (images != null && images.isNotEmpty) {
        for (final imgData in images) {
          final checkImage = CheckImage(
            uuid: imgData.uuid,
            checkId: checkId,
            fileName: imgData.fileName,
            kind: imgData.kind,
            sortOrder: imgData.sortOrder,
            sizeBytes: imgData.sizeBytes,
            sha256: imgData.sha256,
            createdAt: nowIso,
          );
          await _imagesDao.insert(checkImage, txn: txn);
        }
      }

      return checkId;
    });
  }

  /// Update an existing check
  Future<void> updateCheck({
    required int id,
    required String checkNumber,
    required int amountCents,
    required String checkDate,
    required String receivedDate,
    required String giverName,
    String? drawerName,
    String? paidToName,
    String? paidDate,
    String? notes,
    required String createdAt,
    List<ProcessedImageData>? newImages,
    List<int>? deleteImageIds,
    List<({int id, int sortOrder, String kind})>? updateImagesOrderKind,
  }) async {
    final db = await _dbHelper.database;

    // Check duplicate check number excluding this id
    final exists = await _checksDao.existsNumber(checkNumber, excludeId: id);
    if (exists) {
      throw StateError('Le numéro de chèque "$checkNumber" est déjà utilisé par un autre chèque.');
    }

    // 1. Delete image files from disk for images requested to be removed
    if (deleteImageIds != null && deleteImageIds.isNotEmpty) {
      for (final imgId in deleteImageIds) {
        final existingImgs = await _imagesDao.getByCheckId(id);
        final match = existingImgs.where((img) => img.id == imgId);
        if (match.isNotEmpty) {
          await _imageService.deleteImageFiles(match.first.fileName);
        }
      }
    }

    await db.transaction((txn) async {
      final currentImgs = await _imagesDao.getByCheckId(id, txn: txn);
      final remainingCount = currentImgs.length - (deleteImageIds?.length ?? 0) + (newImages?.length ?? 0);
      if (remainingCount > AppConstants.maxImagesPerCheck) {
        throw StateError('Maximum ${AppConstants.maxImagesPerCheck} images autorisées par chèque.');
      }

      final giver = await _personsDao.findOrCreate(giverName, txn: txn);

      Person? drawer;
      if (drawerName != null && drawerName.trim().isNotEmpty) {
        drawer = await _personsDao.findOrCreate(drawerName, txn: txn);
      }

      Person? paidTo;
      if (paidToName != null && paidToName.trim().isNotEmpty) {
        paidTo = await _personsDao.findOrCreate(paidToName, txn: txn);
      }

      final nowIso = DateTime.now().toIso8601String();
      final existing = await _checksDao.getRawById(id, txn: txn);
      final check = Check(
        id: id,
        uuid: existing?.uuid,
        checkNumber: checkNumber.trim(),
        amountCents: amountCents,
        checkDate: checkDate,
        receivedDate: receivedDate,
        giverId: giver.id!,
        drawerId: drawer?.id,
        paidToId: paidTo?.id,
        paidDate: paidTo != null ? paidDate : null,
        notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
        createdAt: createdAt,
        updatedAt: nowIso,
      );

      await _checksDao.update(check, txn: txn);

      // Delete images from database
      if (deleteImageIds != null && deleteImageIds.isNotEmpty) {
        for (final imgId in deleteImageIds) {
          await _imagesDao.deleteById(imgId, txn: txn);
        }
      }

      // Update existing images order/kind
      if (updateImagesOrderKind != null) {
        for (final item in updateImagesOrderKind) {
          await _imagesDao.updateOrder(item.id, item.sortOrder, txn: txn);
          await _imagesDao.updateKind(item.id, item.kind, txn: txn);
        }
      }

      // Insert newly added images
      if (newImages != null && newImages.isNotEmpty) {
        for (final imgData in newImages) {
          final checkImage = CheckImage(
            uuid: imgData.uuid,
            checkId: id,
            fileName: imgData.fileName,
            kind: imgData.kind,
            sortOrder: imgData.sortOrder,
            sizeBytes: imgData.sizeBytes,
            sha256: imgData.sha256,
            createdAt: nowIso,
          );
          await _imagesDao.insert(checkImage, txn: txn);
        }
      }
    });
  }

  /// Mark check as used
  Future<void> markAsUsed({
    required int id,
    required String paidToName,
    required String paidDate,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final paidTo = await _personsDao.findOrCreate(paidToName, txn: txn);
      await _checksDao.markAsUsed(
        id: id,
        paidToId: paidTo.id!,
        paidDate: paidDate,
        txn: txn,
      );
    });
  }

  /// Cancel payment (revert to stock)
  Future<void> cancelPayment(int id) async {
    await _checksDao.cancelPayment(id);
  }

  /// Soft delete (move to trash)
  Future<void> softDelete(int id) => _checksDao.softDelete(id);

  /// Restore from trash
  Future<void> restore(int id) => _checksDao.restore(id);

  /// Hard delete permanently: deletes disk image files and database records
  Future<void> hardDelete(int id) async {
    final images = await _imagesDao.getByCheckId(id);
    for (final img in images) {
      await _imageService.deleteImageFiles(img.fileName);
    }
    await _imagesDao.deleteByCheckId(id);
    await _checksDao.hardDelete(id);
  }

  /// Empty trash completely: deletes disk image files for all trash checks
  Future<void> emptyTrash() async {
    final trashChecks = await _checksDao.getTrashChecks();
    for (final c in trashChecks) {
      if (c.id != null) {
        final images = await _imagesDao.getByCheckId(c.id!);
        for (final img in images) {
          await _imageService.deleteImageFiles(img.fileName);
        }
        await _imagesDao.deleteByCheckId(c.id!);
      }
    }
    await _checksDao.emptyTrash();
  }

  /// Get check by id
  Future<CheckWithNames?> getById(int id) => _checksDao.getById(id);

  /// Query checks
  Future<List<CheckWithNames>> query(CheckFilter filter) => _checksDao.getChecks(filter);

  /// Get statistics
  Future<CheckStats> getStats() => _checksDao.getStats();

  /// Get trash items
  Future<List<CheckWithNames>> getTrashChecks() => _checksDao.getTrashChecks();

  /// Get images for a check
  Future<List<CheckImage>> getCheckImages(int checkId) => _imagesDao.getByCheckId(checkId);

  /// Delete a single check image
  Future<void> deleteCheckImage(int checkId, int imageId) async {
    final images = await _imagesDao.getByCheckId(checkId);
    final match = images.where((i) => i.id == imageId);
    if (match.isNotEmpty) {
      await _imageService.deleteImageFiles(match.first.fileName);
      await _imagesDao.deleteById(imageId);
    }
  }
}
