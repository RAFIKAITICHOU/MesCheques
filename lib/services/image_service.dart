import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ProcessedImageData {
  final String uuid;
  final String fileName;
  final String kind;
  final int sortOrder;
  final int sizeBytes;
  final String sha256;
  final Uint8List thumbnailBytes;

  ProcessedImageData({
    required this.uuid,
    required this.fileName,
    required this.kind,
    required this.sortOrder,
    required this.sizeBytes,
    required this.sha256,
    required this.thumbnailBytes,
  });
}

class ImageService {
  static final ImageService instance = ImageService._internal();

  FlutterSecureStorage _storage;
  Directory? _storageDir;
  Uint8List? _masterKey;
  final Map<String, Uint8List> _thumbnailCache = {};

  static const String _keyMasterKey = 'check_images_aes_master_key';
  static const int _maxDimensionFull = 1600;
  static const int _qualityFull = 80;
  static const int _maxDimensionThumb = 200;
  static const int _qualityThumb = 70;

  ImageService({
    FlutterSecureStorage? storage,
    this._storageDir,
  })  : _storage = storage ?? const FlutterSecureStorage();

  ImageService._internal() : _storage = const FlutterSecureStorage();

  /// Visible for testing: inject custom storage dir or clear cache
  void setStorageDirForTesting(Directory dir) {
    _storageDir = dir;
  }

  void setStorageForTesting(FlutterSecureStorage storage) {
    _storage = storage;
    _masterKey = null;
  }

  void clearCache() {
    _thumbnailCache.clear();
  }

  /// Ensure master AES-256 key exists in secure storage
  Future<Uint8List> _getMasterKey() async {
    if (_masterKey != null) return _masterKey!;

    final storedB64 = await _storage.read(key: _keyMasterKey);
    if (storedB64 != null && storedB64.isNotEmpty) {
      _masterKey = base64Decode(storedB64);
      return _masterKey!;
    }

    // Generate random 256-bit (32 bytes) key
    final rnd = Random.secure();
    final keyBytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      keyBytes[i] = rnd.nextInt(256);
    }

    await _storage.write(key: _keyMasterKey, value: base64Encode(keyBytes));
    _masterKey = keyBytes;
    return _masterKey!;
  }

  /// Directory where encrypted check images reside
  Future<Directory> getImagesDirectory() async {
    if (_storageDir != null) return _storageDir!;
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, 'check_images'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _storageDir = dir;
    return dir;
  }

  /// Encrypt arbitrary bytes with AES-GCM (returns [12-byte nonce] + [16-byte MAC] + [ciphertext])
  Future<Uint8List> encryptBytes(Uint8List plaintext) async {
    final keyBytes = await _getMasterKey();
    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(keyBytes);

    final secretBox = await algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
    );

    final nonce = secretBox.nonce;
    final macBytes = secretBox.mac.bytes;
    final cipherText = secretBox.cipherText;

    final output = Uint8List(12 + 16 + cipherText.length);
    output.setRange(0, 12, nonce);
    output.setRange(12, 28, macBytes);
    output.setRange(28, output.length, cipherText);
    return output;
  }

  /// Decrypt bytes produced by encryptBytes
  Future<Uint8List> decryptBytes(Uint8List encryptedData) async {
    if (encryptedData.length < 28) {
      throw const FormatException('Données chiffrées invalides (taille insuffisante).');
    }

    final keyBytes = await _getMasterKey();
    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(keyBytes);

    final nonce = encryptedData.sublist(0, 12);
    final mac = Mac(encryptedData.sublist(12, 28));
    final cipherText = encryptedData.sublist(28);

    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    final decryptedList = await algorithm.decrypt(secretBox, secretKey: secretKey);
    return Uint8List.fromList(decryptedList);
  }

  /// Compresses and normalizes raw image bytes using `image` package
  /// Returns a record with full JPEG bytes, thumbnail JPEG bytes, and SHA-256
  ({Uint8List fullBytes, Uint8List thumbBytes, String sha256}) compressAndGenerateThumbnail(Uint8List rawBytes) {
    // 1. Decode image (automatically honors EXIF orientation)
    img.Image? decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      throw const FormatException('Impossible de décoder le fichier image.');
    }

    // Auto-orient based on EXIF metadata if present
    decoded = img.bakeOrientation(decoded);

    // 2. Resize for full image (max 1600 px long edge)
    img.Image fullImg = decoded;
    if (decoded.width > _maxDimensionFull || decoded.height > _maxDimensionFull) {
      if (decoded.width >= decoded.height) {
        fullImg = img.copyResize(decoded, width: _maxDimensionFull);
      } else {
        fullImg = img.copyResize(decoded, height: _maxDimensionFull);
      }
    }
    final fullJpeg = Uint8List.fromList(img.encodeJpg(fullImg, quality: _qualityFull));

    // 3. Compute SHA-256
    final hash = crypto.sha256.convert(fullJpeg).toString();

    // 4. Resize for thumbnail (max 200 px long edge)
    img.Image thumbImg = fullImg;
    if (fullImg.width > _maxDimensionThumb || fullImg.height > _maxDimensionThumb) {
      if (fullImg.width >= fullImg.height) {
        thumbImg = img.copyResize(fullImg, width: _maxDimensionThumb);
      } else {
        thumbImg = img.copyResize(fullImg, height: _maxDimensionThumb);
      }
    }
    final thumbJpeg = Uint8List.fromList(img.encodeJpg(thumbImg, quality: _qualityThumb));

    return (fullBytes: fullJpeg, thumbBytes: thumbJpeg, sha256: hash);
  }

  /// Process raw picked image bytes, compress, encrypt, and save to disk
  Future<ProcessedImageData> processAndSaveNewImage({
    required Uint8List rawBytes,
    String kind = 'front',
    int sortOrder = 0,
  }) async {
    final processed = compressAndGenerateThumbnail(rawBytes);

    final uuid = const Uuid().v4();
    final fileName = '$uuid.img';
    final thumbFileName = '${uuid}_thumb.img';

    final dir = await getImagesDirectory();

    // Encrypt full image
    final encFull = await encryptBytes(processed.fullBytes);
    final fullFile = File(p.join(dir.path, fileName));
    await fullFile.writeAsBytes(encFull, flush: true);

    // Encrypt thumbnail
    final encThumb = await encryptBytes(processed.thumbBytes);
    final thumbFile = File(p.join(dir.path, thumbFileName));
    await thumbFile.writeAsBytes(encThumb, flush: true);

    // Cache thumbnail in memory
    _thumbnailCache[fileName] = processed.thumbBytes;

    return ProcessedImageData(
      uuid: uuid,
      fileName: fileName,
      kind: kind,
      sortOrder: sortOrder,
      sizeBytes: processed.fullBytes.length,
      sha256: processed.sha256,
      thumbnailBytes: processed.thumbBytes,
    );
  }

  /// Load and decrypt full resolution image bytes from disk
  Future<Uint8List> loadImageBytes(String fileName) async {
    final dir = await getImagesDirectory();
    final file = File(p.join(dir.path, fileName));
    if (!await file.exists()) {
      throw FileSystemException('Fichier image introuvable', file.path);
    }
    final encBytes = await file.readAsBytes();
    return await decryptBytes(encBytes);
  }

  /// Load and decrypt thumbnail image bytes (checks cache first)
  Future<Uint8List> loadThumbnailBytes(String fileName) async {
    if (_thumbnailCache.containsKey(fileName)) {
      return _thumbnailCache[fileName]!;
    }

    final dir = await getImagesDirectory();
    final uuid = fileName.replaceAll('.img', '');
    final thumbFileName = '${uuid}_thumb.img';
    final thumbFile = File(p.join(dir.path, thumbFileName));

    if (await thumbFile.exists()) {
      final encBytes = await thumbFile.readAsBytes();
      final decrypted = await decryptBytes(encBytes);
      _thumbnailCache[fileName] = decrypted;
      return decrypted;
    }

    // Fallback to loading full image and generating thumbnail if thumb file is absent
    final fullBytes = await loadImageBytes(fileName);
    final thumb = compressAndGenerateThumbnail(fullBytes).thumbBytes;
    _thumbnailCache[fileName] = thumb;
    return thumb;
  }

  /// Check if image file exists on disk
  Future<bool> imageExists(String fileName) async {
    final dir = await getImagesDirectory();
    final file = File(p.join(dir.path, fileName));
    return await file.exists();
  }

  /// Delete image file and its thumbnail from disk
  Future<void> deleteImageFiles(String fileName) async {
    _thumbnailCache.remove(fileName);
    final dir = await getImagesDirectory();

    final fullFile = File(p.join(dir.path, fileName));
    if (await fullFile.exists()) {
      try {
        await fullFile.delete();
      } catch (_) {}
    }

    final uuid = fileName.replaceAll('.img', '');
    final thumbFile = File(p.join(dir.path, '${uuid}_thumb.img'));
    if (await thumbFile.exists()) {
      try {
        await thumbFile.delete();
      } catch (_) {}
    }
  }

  /// Clean up orphan files on disk that do not exist in the active check_images database table
  Future<int> cleanupOrphanFiles(List<String> validFileNames) async {
    final dir = await getImagesDirectory();
    if (!await dir.exists()) return 0;

    final validSet = validFileNames.toSet();
    final validThumbSet = validFileNames.map((fn) => '${fn.replaceAll(".img", "")}_thumb.img').toSet();

    int deletedCount = 0;
    final entities = dir.listSync();
    for (final entity in entities) {
      if (entity is File) {
        final basename = p.basename(entity.path);
        if (!validSet.contains(basename) && !validThumbSet.contains(basename)) {
          try {
            entity.deleteSync();
            deletedCount++;
          } catch (_) {}
        }
      }
    }
    return deletedCount;
  }

  /// Directly save an already decrypted/raw image file (e.g. from backup restoration)
  Future<void> restoreImageFromBackup({
    required String fileName,
    required Uint8List imageBytes,
  }) async {
    final processed = compressAndGenerateThumbnail(imageBytes);

    final dir = await getImagesDirectory();
    final uuid = fileName.replaceAll('.img', '');
    final thumbFileName = '${uuid}_thumb.img';

    // Encrypt and write full image
    final encFull = await encryptBytes(processed.fullBytes);
    final fullFile = File(p.join(dir.path, fileName));
    await fullFile.writeAsBytes(encFull, flush: true);

    // Encrypt and write thumbnail
    final encThumb = await encryptBytes(processed.thumbBytes);
    final thumbFile = File(p.join(dir.path, thumbFileName));
    await thumbFile.writeAsBytes(encThumb, flush: true);

    _thumbnailCache[fileName] = processed.thumbBytes;
  }
}
