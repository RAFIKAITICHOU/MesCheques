import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../models/check_image.dart';
import '../services/image_service.dart';
import '../utils/constants.dart';
import 'image_viewer.dart';

class FormImageItem {
  final int? id; // null if newly added
  final String uuid;
  final String fileName;
  String kind; // 'front', 'back', 'other'
  int sortOrder;
  final int sizeBytes;
  final String sha256;
  final Uint8List thumbnailBytes;
  final Uint8List? rawBytes; // populated for new images
  final bool isNew;

  FormImageItem({
    this.id,
    required this.uuid,
    required this.fileName,
    required this.kind,
    required this.sortOrder,
    required this.sizeBytes,
    required this.sha256,
    required this.thumbnailBytes,
    this.rawBytes,
    this.isNew = false,
  });

  factory FormImageItem.fromCheckImage(CheckImage img, Uint8List thumb) {
    return FormImageItem(
      id: img.id,
      uuid: img.uuid,
      fileName: img.fileName,
      kind: img.kind,
      sortOrder: img.sortOrder,
      sizeBytes: img.sizeBytes,
      sha256: img.sha256,
      thumbnailBytes: thumb,
      isNew: false,
    );
  }
}

class ImagePickerRow extends StatefulWidget {
  final List<FormImageItem> images;
  final ValueChanged<List<FormImageItem>> onImagesChanged;

  const ImagePickerRow({
    super.key,
    required this.images,
    required this.onImagesChanged,
  });

  @override
  State<ImagePickerRow> createState() => _ImagePickerRowState();
}

class _ImagePickerRowState extends State<ImagePickerRow> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _pickImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;

    if (widget.images.length >= AppConstants.maxImagesPerCheck) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.maxImagesReached),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    try {
      final XFile? file = await _picker.pickImage(source: source);
      if (file == null) return;

      setState(() => _isProcessing = true);

      final bytes = await file.readAsBytes();

      // Clean up temporary image_picker cache file immediately
      try {
        final tmpFile = File(file.path);
        if (await tmpFile.exists()) {
          await tmpFile.delete();
        }
      } catch (_) {}

      // Compress and compute SHA-256
      final processed = ImageService.instance.compressAndGenerateThumbnail(bytes);

      // Check for duplicate on this check
      final isDuplicate = widget.images.any((img) => img.sha256 == processed.sha256);
      if (isDuplicate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.duplicateImageWarning),
              backgroundColor: AppColors.accentWarning,
            ),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      // Determine default kind (front for 1st, back for 2nd, other for rest)
      String defaultKind = 'other';
      if (!widget.images.any((img) => img.kind == 'front')) {
        defaultKind = 'front';
      } else if (!widget.images.any((img) => img.kind == 'back')) {
        defaultKind = 'back';
      }

      final newItem = FormImageItem(
        uuid: DateTime.now().microsecondsSinceEpoch.toString(),
        fileName: '', // assigned when saved
        kind: defaultKind,
        sortOrder: widget.images.length,
        sizeBytes: processed.fullBytes.length,
        sha256: processed.sha256,
        thumbnailBytes: processed.thumbBytes,
        rawBytes: processed.fullBytes,
        isNew: true,
      );

      final updatedList = List<FormImageItem>.from(widget.images)..add(newItem);
      widget.onImagesChanged(updatedList);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout de l\'image : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showAddOptions() {
    final l10n = AppLocalizations.of(context)!;
    if (widget.images.length >= AppConstants.maxImagesPerCheck) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.maxImagesReached),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 28),
                title: Text(l10n.takePhoto, style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary, size: 28),
                title: Text(l10n.chooseImage, style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _cycleKind(int index) {
    final item = widget.images[index];
    String nextKind;
    if (item.kind == 'front') {
      nextKind = 'back';
    } else if (item.kind == 'back') {
      nextKind = 'other';
    } else {
      nextKind = 'front';
    }

    setState(() {
      item.kind = nextKind;
    });
    widget.onImagesChanged(widget.images);
  }

  void _removeImage(int index) {
    final updated = List<FormImageItem>.from(widget.images)..removeAt(index);
    for (int i = 0; i < updated.length; i++) {
      updated[i].sortOrder = i;
    }
    widget.onImagesChanged(updated);
  }

  String _getKindBadgeLabel(String kind, AppLocalizations l10n) {
    switch (kind) {
      case 'front':
        return l10n.front;
      case 'back':
        return l10n.back;
      default:
        return l10n.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.images,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '${widget.images.length} / ${AppConstants.maxImagesPerCheck}',
              style: TextStyle(
                fontSize: 12,
                color: widget.images.length >= AppConstants.maxImagesPerCheck
                    ? AppColors.danger
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 104,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                ...List.generate(widget.images.length, (index) {
                final item = widget.images[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: () {
                          final viewerItems = widget.images.map((img) {
                            return ImageViewerItem(
                              fileName: img.fileName,
                              kind: img.kind,
                              memoryBytes: img.rawBytes,
                            );
                          }).toList();
                          ImageViewer.show(
                            context,
                            items: viewerItems,
                            initialIndex: index,
                          );
                        },
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border, width: 1.5),
                            color: Colors.grey.shade100,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(
                                item.thumbnailBytes,
                                fit: BoxFit.cover,
                              ),
                              // Kind badge at bottom
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: () => _cycleKind(index),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    color: Colors.black.withAlpha(160),
                                    child: Text(
                                      _getKindBadgeLabel(item.kind, l10n),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Remove button
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Add image card
              if (widget.images.length < AppConstants.maxImagesPerCheck)
                GestureDetector(
                  onTap: _isProcessing ? null : _showAddOptions,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(100),
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                      color: AppColors.primaryLight.withAlpha(80),
                    ),
                    child: _isProcessing
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 26),
                              SizedBox(height: 4),
                              Icon(Icons.add, color: AppColors.primary, size: 18),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
