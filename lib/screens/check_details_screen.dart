import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/check.dart';
import '../models/check_image.dart';
import '../providers/checks_provider.dart';
import '../providers/locale_provider.dart';
import '../repositories/check_repository.dart';
import '../services/image_service.dart';
import '../services/pdf_service.dart';
import '../utils/bidi_helper.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/image_viewer.dart';
import '../widgets/person_autocomplete.dart';
import '../widgets/status_badge.dart';
import 'edit_check_screen.dart';

class CheckDetailsScreen extends StatefulWidget {
  final int checkId;

  const CheckDetailsScreen({
    super.key,
    required this.checkId,
  });

  @override
  State<CheckDetailsScreen> createState() => _CheckDetailsScreenState();
}

class _CheckDetailsScreenState extends State<CheckDetailsScreen> {
  final CheckRepository _repo = CheckRepository();
  CheckWithNames? _check;
  List<CheckImage> _images = [];
  final Map<String, Uint8List> _thumbnails = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final item = await _repo.getById(widget.checkId);
    final imgs = await _repo.getCheckImages(widget.checkId);
    final thumbs = <String, Uint8List>{};

    for (final img in imgs) {
      try {
        thumbs[img.fileName] = await ImageService.instance.loadThumbnailBytes(img.fileName);
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _check = item;
        _images = imgs;
        _thumbnails.clear();
        _thumbnails.addAll(thumbs);
        _isLoading = false;
      });
    }
  }

  Future<void> _showMarkAsUsedDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.read<LocaleProvider>();
    final isArabic = localeProvider.isArabic;

    String paidToName = '';
    DateTime paidDate = DateTime.now();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.used, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          l10n.markAsUsedTitle,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx, false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.markAsUsedDesc,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    PersonAutocomplete(
                      label: l10n.givenTo,
                      hint: l10n.receiverHint,
                      isRequired: true,
                      prefixIcon: Icons.person_pin_outlined,
                      onSelected: (val) {
                        setSheetState(() => paidToName = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: paidDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          locale: localeProvider.locale,
                        );
                        if (picked != null) {
                          setSheetState(() => paidDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: '${l10n.paymentDate} *',
                          prefixIcon: const Icon(Icons.event_outlined, size: 20),
                        ),
                        child: Text(
                          Formatters.formatDate(Formatters.toIsoDate(paidDate), isArabic: isArabic),
                          style: const TextStyle(fontSize: 14.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (paidToName.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.receiverRequired)),
                            );
                            return;
                          }
                          Navigator.pop(ctx, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.used,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(l10n.confirmPayment),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      final provider = context.read<ChecksProvider>();
      await provider.markAsUsed(
        id: widget.checkId,
        paidToName: paidToName.trim(),
        paidDate: Formatters.toIsoDate(paidDate),
      );
      await _loadDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.checkMarkedAsUsed)),
        );
      }
    }
  }

  Future<void> _cancelPayment() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelPaymentTitle),
        content: Text(l10n.cancelPaymentDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.back),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<ChecksProvider>();
      await provider.cancelPayment(widget.checkId);
      await _loadDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paymentCancelled)),
        );
      }
    }
  }

  Future<void> _deleteCheck() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteCheckTitle),
        content: Text(l10n.deleteCheckDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<ChecksProvider>();
      await provider.softDeleteCheck(widget.checkId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.checkMovedToTrash)),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _exportFicheCheque() async {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.read<LocaleProvider>();
    final isArabic = localeProvider.isArabic;

    if (_images.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 28),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.exportFicheCheque)),
            ],
          ),
          content: Text(l10n.exportWarningImages),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(l10n.share),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    try {
      final fullImageBytes = <Uint8List>[];
      for (final img in _images) {
        try {
          final b = await ImageService.instance.loadImageBytes(img.fileName);
          fullImageBytes.add(b);
        } catch (_) {}
      }

      await PdfService.shareSingleCheckPdf(
        check: _check!,
        imageBytes: fullImageBytes.isNotEmpty ? fullImageBytes : null,
        localeCode: isArabic ? 'ar' : 'fr',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur export PDF : $e')),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();
    final isArabic = localeProvider.isArabic;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final item = _check;
    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.checkDetails)),
        body: Center(child: Text(l10n.checkNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.checkDetails),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: l10n.exportFicheCheque,
            onPressed: _exportFicheCheque,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.edit,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditCheckScreen(check: item),
                ),
              );
              _loadDetails();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            tooltip: l10n.delete,
            onPressed: _deleteCheck,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Check Images Gallery (if images exist)
            if (_images.isNotEmpty) ...[
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _images.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (ctx, idx) {
                    final img = _images[idx];
                    final thumbBytes = _thumbnails[img.fileName];

                    return GestureDetector(
                      onTap: () {
                        final viewerItems = _images.map((i) {
                          return ImageViewerItem(fileName: i.fileName, kind: i.kind);
                        }).toList();
                        ImageViewer.show(context, items: viewerItems, initialIndex: idx);
                      },
                      child: Container(
                        width: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 1.5),
                          color: Colors.grey.shade100,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (thumbBytes != null)
                              Image.memory(thumbBytes, fit: BoxFit.cover)
                            else
                              const Center(child: Icon(Icons.image_outlined, color: AppColors.textMuted)),
                            // Badge at bottom
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                color: Colors.black.withAlpha(160),
                                child: Text(
                                  _getKindLabel(img.kind, l10n),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Amount & Status Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusBadge(isInStock: item.isInStock),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            item.checkNumber,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Directionality(
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    child: Text(
                      Formatters.formatAmount(item.amountCents, isArabic: isArabic),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.amountOfCheck,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // SECTION TITULAIRE
            _buildDetailSection(
              title: l10n.drawer,
              icon: Icons.account_balance_outlined,
              color: AppColors.primary,
              children: [
                _buildInfoRow(
                  label: l10n.drawer,
                  value: item.drawerName ?? item.giverName,
                  isBold: true,
                ),
                if (!item.isDrawerDifferent) ...[
                  const Divider(),
                  _buildInfoRow(
                    label: l10n.status,
                    value: l10n.sameAsGiver,
                    valueColor: AppColors.textSecondary,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // SECTION RÉCEPTION
            _buildDetailSection(
              title: l10n.receptionSection,
              icon: Icons.input_rounded,
              color: AppColors.primary,
              children: [
                _buildInfoRow(
                  label: l10n.givenByIssuer,
                  value: item.giverName,
                  isBold: true,
                ),
                const Divider(),
                _buildInfoRow(
                  label: l10n.receivedDate,
                  value: Formatters.formatDate(item.receivedDate, isArabic: isArabic),
                ),
                const Divider(),
                _buildInfoRow(
                  label: l10n.dateOnCheck,
                  value: Formatters.formatDate(item.checkDate, isArabic: isArabic),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SECTION PAIEMENT
            _buildDetailSection(
              title: l10n.paymentSection,
              icon: Icons.outbox_rounded,
              color: item.isUsed ? AppColors.used : AppColors.inStock,
              children: [
                if (item.isUsed) ...[
                  _buildInfoRow(
                    label: l10n.givenToReceiver,
                    value: item.paidToName ?? l10n.receiverUnknown,
                    isBold: true,
                    valueColor: AppColors.used,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    label: l10n.paymentDate,
                    value: Formatters.formatDate(item.paidDate, isArabic: isArabic),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _cancelPayment,
                    icon: const Icon(Icons.undo, size: 18),
                    label: Text(l10n.cancelPaymentBtn),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.inStockBg.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, color: AppColors.inStock, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.stockNotice,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _showMarkAsUsedDialog,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(l10n.markAsUsed),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.used,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ],
            ),

            // SECTION REMARQUES
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailSection(
                title: l10n.notes,
                icon: Icons.note_alt_outlined,
                color: AppColors.textSecondary,
                children: [
                  Text(
                    item.notes!,
                    textDirection: BidiHelper.detectDirection(
                      item.notes!,
                      defaultDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    bool isBold = false,
    Color? valueColor,
  }) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final valueDirection = BidiHelper.detectDirection(
      value,
      defaultDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              textDirection: valueDirection,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
