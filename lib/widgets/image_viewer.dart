import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../services/image_service.dart';
import '../utils/constants.dart';

class ImageViewerItem {
  final String fileName;
  final String kind;
  final Uint8List? memoryBytes;

  const ImageViewerItem({
    required this.fileName,
    required this.kind,
    this.memoryBytes,
  });
}

class ImageViewer extends StatefulWidget {
  final List<ImageViewerItem> items;
  final int initialIndex;

  const ImageViewer({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required List<ImageViewerItem> items,
    int initialIndex = 0,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ImageViewer(
          items: items,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late int _currentIndex;
  late PageController _pageController;
  final Map<int, Uint8List> _loadedBytes = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadCurrentImage();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentImage() async {
    if (_loadedBytes.containsKey(_currentIndex)) return;

    final item = widget.items[_currentIndex];
    if (item.memoryBytes != null) {
      setState(() {
        _loadedBytes[_currentIndex] = item.memoryBytes!;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bytes = await ImageService.instance.loadImageBytes(item.fileName);
      if (mounted) {
        setState(() {
          _loadedBytes[_currentIndex] = bytes;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getKindLabel(String kind, AppLocalizations l10n) {
    switch (kind) {
      case 'front':
        return l10n.front;
      case 'back':
        return l10n.back;
      default:
        return l10n.other;
    }
  }

  Future<void> _shareImage() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 28),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.warningTitle)),
          ],
        ),
        content: Text(l10n.shareImageWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.share),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final currentBytes = _loadedBytes[_currentIndex];
    if (currentBytes == null) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, 'cheque_export_${DateTime.now().millisecondsSinceEpoch}.jpg'));
      await tempFile.writeAsBytes(currentBytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path)],
          text: l10n.shareCheckImageText,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du partage : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentItem = widget.items[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withAlpha(200),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getKindLabel(currentItem.kind, l10n),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_currentIndex + 1} / ${widget.items.length}',
              style: const TextStyle(fontSize: 15, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            tooltip: l10n.share,
            onPressed: _shareImage,
          ),
        ],
      ),
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            itemCount: widget.items.length,
            pageController: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              _loadCurrentImage();
            },
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (context, index) {
              final bytes = _loadedBytes[index];
              if (bytes == null) {
                return PhotoViewGalleryPageOptions.customChild(
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              }
              return PhotoViewGalleryPageOptions(
                imageProvider: MemoryImage(bytes),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.covered * 3.0,
                heroAttributes: PhotoViewHeroAttributes(tag: 'img_${widget.items[index].fileName}'),
              );
            },
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }
}
