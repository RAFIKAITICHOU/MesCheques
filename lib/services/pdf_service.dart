import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/check.dart';
import '../models/check_filter.dart';
import '../services/image_service.dart';
import '../utils/formatters.dart';

class PdfService {
  /// Generate and preview/print PDF for a list of checks
  static Future<void> printChecksList({
    required List<CheckWithNames> checks,
    required CheckFilter filter,
    bool withThumbnails = false,
    String localeCode = 'fr',
  }) async {
    final pdfBytes = await generateChecksPdf(
      checks: checks,
      filter: filter,
      withThumbnails: withThumbnails,
      localeCode: localeCode,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'MesCheques_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Generate and share PDF file directly
  static Future<void> shareChecksPdf({
    required List<CheckWithNames> checks,
    required CheckFilter filter,
    bool withThumbnails = false,
    String localeCode = 'fr',
  }) async {
    final pdfBytes = await generateChecksPdf(
      checks: checks,
      filter: filter,
      withThumbnails: withThumbnails,
      localeCode: localeCode,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'MesCheques_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Generate PDF Document bytes for checks list
  static Future<Uint8List> generateChecksPdf({
    required List<CheckWithNames> checks,
    required CheckFilter filter,
    bool withThumbnails = false,
    String localeCode = 'fr',
  }) async {
    final isAr = localeCode.startsWith('ar');

    // Load bundled Cairo font that supports both Arabic and Latin
    final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final fontBoldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    final font = pw.Font.ttf(fontData);
    final fontBold = pw.Font.ttf(fontBoldData);

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: font,
        bold: fontBold,
      ),
    );

    // Pre-load thumbnails if requested
    final thumbnails = <int, pw.MemoryImage>{};
    if (withThumbnails) {
      final imgService = ImageService.instance;
      for (int i = 0; i < checks.length; i++) {
        final c = checks[i];
        if (c.primaryImageFileName != null) {
          try {
            final thumbBytes = await imgService.loadThumbnailBytes(c.primaryImageFileName!);
            thumbnails[i] = pw.MemoryImage(thumbBytes);
          } catch (_) {}
        }
      }
    }

    final now = DateTime.now();
    final exportDateStr = Formatters.formatDate(Formatters.toIsoDate(now), locale: localeCode);

    // Calculate totals
    final totalAmountCents = checks.fold<int>(0, (sum, c) => sum + c.amountCents);

    // Build filter description string
    final filterParts = <String>[];
    if (isAr) {
      switch (filter.status) {
        case CheckStatusFilter.stock:
          filterParts.add('الحالة: في المخزون');
          break;
        case CheckStatusFilter.used:
          filterParts.add('الحالة: مستعمل');
          break;
        case CheckStatusFilter.all:
          filterParts.add('الحالة: الكل');
          break;
      }
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        filterParts.add('بحث: "${filter.searchQuery}"');
      }
      if (filter.minAmountCents != null) {
        filterParts.add('أدنى: ${Formatters.formatAmount(filter.minAmountCents!, isArabic: true)}');
      }
      if (filter.maxAmountCents != null) {
        filterParts.add('أقصى: ${Formatters.formatAmount(filter.maxAmountCents!, isArabic: true)}');
      }
    } else {
      switch (filter.status) {
        case CheckStatusFilter.stock:
          filterParts.add('Statut : En stock');
          break;
        case CheckStatusFilter.used:
          filterParts.add('Statut : Utilisé');
          break;
        case CheckStatusFilter.all:
          filterParts.add('Statut : Tous');
          break;
      }
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        filterParts.add('Recherche : "${filter.searchQuery}"');
      }
      if (filter.minAmountCents != null) {
        filterParts.add('Min : ${Formatters.formatAmount(filter.minAmountCents!)}');
      }
      if (filter.maxAmountCents != null) {
        filterParts.add('Max : ${Formatters.formatAmount(filter.maxAmountCents!)}');
      }
    }

    final filtersSummary = filterParts.join(' · ');
    final sortSummary = filter.sortOption.label;

    final titleText = isAr ? 'شيكاتي : قائمة الشيكات' : 'MESCHEQUES : Liste des chèques';
    final dateExportLabel = isAr ? 'تاريخ التصدير : $exportDateStr' : 'Exporté le : $exportDateStr';
    final filterLabel = isAr ? 'التصفية : $filtersSummary' : 'Filtres : $filtersSummary';
    final sortLabel = isAr ? 'الترتيب : $sortSummary' : 'Tri : $sortSummary';
    final footerTitle = isAr ? 'شيكاتي - تطبيق الهاتف' : 'MesCheques - Application mobile';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        textDirection: isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    titleText,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('1E4FD8'),
                    ),
                  ),
                  pw.Text(
                    dateExportLabel,
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      filterLabel,
                      style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                    ),
                  ),
                  pw.Text(
                    sortLabel,
                    style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColor.fromHex('1E4FD8')),
              pw.SizedBox(height: 6),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                footerTitle,
                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
              ),
              pw.Text(
                isAr
                    ? 'صفحة ${context.pageNumber} من ${context.pagesCount}'
                    : 'Page ${context.pageNumber} / ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
              ),
            ],
          );
        },
        build: (pw.Context context) {
          final columnWidths = <int, pw.TableColumnWidth>{
            0: const pw.FixedColumnWidth(24),
            if (withThumbnails) 1: const pw.FixedColumnWidth(34),
            withThumbnails ? 2 : 1: const pw.FlexColumnWidth(2.0), // Titulaire
            withThumbnails ? 3 : 2: const pw.FlexColumnWidth(2.0), // Donneur
            withThumbnails ? 4 : 3: const pw.FlexColumnWidth(1.8), // Montant
            withThumbnails ? 5 : 4: const pw.FlexColumnWidth(1.6), // N° chèque
            withThumbnails ? 6 : 5: const pw.FlexColumnWidth(1.4), // Date chèque
            withThumbnails ? 7 : 6: const pw.FlexColumnWidth(2.0), // Payé à
            withThumbnails ? 8 : 7: const pw.FlexColumnWidth(1.3), // Statut
          };

          return [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: columnWidths,
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('EEF2FF')),
                  children: [
                    _buildTableCell('#', isHeader: true, align: pw.TextAlign.center),
                    if (withThumbnails)
                      _buildTableCell(isAr ? 'الصورة' : 'Image', isHeader: true, align: pw.TextAlign.center),
                    _buildTableCell(isAr ? 'صاحب الشيك' : 'Titulaire', isHeader: true),
                    _buildTableCell(isAr ? 'من طرف' : 'Donné par', isHeader: true),
                    _buildTableCell(isAr ? 'المبلغ' : 'Montant', isHeader: true, align: pw.TextAlign.right),
                    _buildTableCell(isAr ? 'رقم الشيك' : 'N° chèque', isHeader: true),
                    _buildTableCell(isAr ? 'تاريخ الشيك' : 'Date chèque', isHeader: true, align: pw.TextAlign.center),
                    _buildTableCell(isAr ? 'مسلَّم إلى / التاريخ' : 'Payé à / Date', isHeader: true),
                    _buildTableCell(isAr ? 'الحالة' : 'Statut', isHeader: true, align: pw.TextAlign.center),
                  ],
                ),
                ...List.generate(checks.length, (index) {
                  final item = checks[index];
                  final isEven = index % 2 == 0;
                  final bgColor = isEven ? PdfColors.white : PdfColor.fromHex('F9FAFB');

                  final drawerDisplay = item.drawerName ?? item.giverName;

                  final paidInfo = item.isUsed
                      ? '${item.paidToName ?? "-"}\n(${Formatters.formatDate(item.paidDate, locale: localeCode)})'
                      : '-';

                  final statusText = item.isInStock
                      ? (isAr ? 'في المخزون' : 'En stock')
                      : (isAr ? 'مستعمل' : 'Utilisé');
                  final statusColor = item.isInStock
                      ? PdfColor.fromHex('B45309')
                      : PdfColor.fromHex('15803D');

                  final thumb = thumbnails[index];

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bgColor),
                    children: [
                      _buildTableCell('${index + 1}', align: pw.TextAlign.center),
                      if (withThumbnails)
                        pw.Container(
                          height: 28,
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.all(2),
                          child: thumb != null
                              ? pw.Image(thumb, width: 26, height: 26, fit: pw.BoxFit.cover)
                              : pw.Text('-', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                        ),
                      _buildTableCell(drawerDisplay, isBold: item.isDrawerDifferent),
                      _buildTableCell(item.giverName, isBold: !item.isDrawerDifferent),
                      _buildTableCell(
                        Formatters.formatAmount(item.amountCents, isArabic: isAr),
                        align: pw.TextAlign.right,
                        isBold: true,
                      ),
                      _buildTableCell(item.checkNumber),
                      _buildTableCell(
                        Formatters.formatDate(item.checkDate, locale: localeCode),
                        align: pw.TextAlign.center,
                      ),
                      _buildTableCell(paidInfo),
                      _buildTableCell(
                        statusText,
                        align: pw.TextAlign.center,
                        textColor: statusColor,
                        isBold: true,
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('F3F4F6'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    isAr ? 'عدد الشيكات : ${checks.length}' : 'Nombre de chèques : ${checks.length}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                  pw.Text(
                    isAr
                        ? 'المبلغ الإجمالي : ${Formatters.formatAmount(totalAmountCents, isArabic: true)}'
                        : 'Montant total : ${Formatters.formatAmount(totalAmountCents)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                      color: PdfColor.fromHex('1E4FD8'),
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return await doc.save();
  }

  /// Generate Single Check PDF (Fiche chèque)
  static Future<Uint8List> generateSingleCheckPdf({
    required CheckWithNames check,
    List<Uint8List>? imageBytes,
    String localeCode = 'fr',
  }) async {
    final isAr = localeCode.startsWith('ar');

    final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final fontBoldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    final font = pw.Font.ttf(fontData);
    final fontBold = pw.Font.ttf(fontBoldData);

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: font,
        bold: fontBold,
      ),
    );

    final now = DateTime.now();
    final exportDateStr = Formatters.formatDate(Formatters.toIsoDate(now), locale: localeCode);

    final title = isAr ? 'بطاقة تفاصيل الشيك' : 'FICHE DÉTAILLÉE DU CHÈQUE';
    final primaryColor = PdfColor.fromHex('1E4FD8');
    final secondaryBg = PdfColor.fromHex('F8FAFC');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        textDirection: isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MESCHEQUES',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor),
                      ),
                      pw.Text(
                        title,
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        isAr ? 'تاريخ التصدير : $exportDateStr' : 'Édité le : $exportDateStr',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                      ),
                      pw.Container(
                        margin: const pw.EdgeInsets.only(top: 4),
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: check.isInStock ? PdfColor.fromHex('FEF3C7') : PdfColor.fromHex('DCFCE7'),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                          border: pw.Border.all(
                            color: check.isInStock ? PdfColor.fromHex('B45309') : PdfColor.fromHex('15803D'),
                            width: 0.5,
                          ),
                        ),
                        child: pw.Text(
                          check.isInStock
                              ? (isAr ? 'في المخزون' : 'En stock')
                              : (isAr ? 'مستعمل' : 'Utilisé'),
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: check.isInStock ? PdfColor.fromHex('B45309') : PdfColor.fromHex('15803D'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1.5, color: primaryColor),
              pw.SizedBox(height: 12),

              // Main Information Box
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: secondaryBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              isAr ? 'رقم الشيك' : 'Numéro du chèque',
                              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                            ),
                            pw.Text(
                              check.checkNumber,
                              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              isAr ? 'المبلغ' : 'Montant',
                              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                            ),
                            pw.Text(
                              Formatters.formatAmount(check.amountCents, isArabic: isAr),
                              style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('047857'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                    pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                    pw.SizedBox(height: 8),

                    // Roles
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: _buildDetailField(
                            isAr ? 'صاحب الشيك (الموقّع)' : 'Titulaire (émetteur)',
                            check.drawerName ?? check.giverName,
                            isHighlighted: check.isDrawerDifferent,
                          ),
                        ),
                        pw.Expanded(
                          child: _buildDetailField(
                            isAr ? 'من طرف (المسلِّم)' : 'Donné par (remis par)',
                            check.giverName,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),

                    // Dates
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildDetailField(
                            isAr ? 'تاريخ الشيك' : 'Date d\'échéance',
                            Formatters.formatDate(check.checkDate, locale: localeCode),
                          ),
                        ),
                        pw.Expanded(
                          child: _buildDetailField(
                            isAr ? 'تاريخ التوصل' : 'Date de réception',
                            Formatters.formatDate(check.receivedDate, locale: localeCode),
                          ),
                        ),
                      ],
                    ),

                    if (check.isUsed) ...[
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: _buildDetailField(
                              isAr ? 'مسلَّم إلى' : 'Payé / Donné à',
                              check.paidToName ?? '-',
                            ),
                          ),
                          pw.Expanded(
                            child: _buildDetailField(
                              isAr ? 'تاريخ الدفع' : 'Date de paiement',
                              Formatters.formatDate(check.paidDate, locale: localeCode),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (check.notes != null && check.notes!.trim().isNotEmpty) ...[
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: _buildDetailField(
                              isAr ? 'ملاحظات' : 'Remarques',
                              check.notes!.trim(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Images Section
              if (imageBytes != null && imageBytes.isNotEmpty) ...[
                pw.Text(
                  isAr ? 'صور الشيك' : 'Images du chèque',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: primaryColor),
                ),
                pw.SizedBox(height: 8),
                pw.Expanded(
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: imageBytes.take(2).map((b) {
                      return pw.Expanded(
                        child: pw.Container(
                          margin: const pw.EdgeInsets.symmetric(horizontal: 4),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                          ),
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Image(
                            pw.MemoryImage(b),
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ] else ...[
                pw.Spacer(),
              ],

              // Footer Note
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 8),
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'MesCheques · Document confidentiel',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                    ),
                    pw.Text(
                      isAr ? 'تم إنشاؤه عبر تطبيق شيكاتي' : 'Généré par MesCheques',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return await doc.save();
  }

  /// Print Single Check PDF
  static Future<void> printSingleCheckPdf({
    required CheckWithNames check,
    List<Uint8List>? imageBytes,
    String localeCode = 'fr',
  }) async {
    final pdfBytes = await generateSingleCheckPdf(
      check: check,
      imageBytes: imageBytes,
      localeCode: localeCode,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Fiche_Cheque_${check.checkNumber}.pdf',
    );
  }

  /// Share Single Check PDF
  static Future<void> shareSingleCheckPdf({
    required CheckWithNames check,
    List<Uint8List>? imageBytes,
    String localeCode = 'fr',
  }) async {
    final pdfBytes = await generateSingleCheckPdf(
      check: check,
      imageBytes: imageBytes,
      localeCode: localeCode,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Fiche_Cheque_${check.checkNumber}.pdf',
    );
  }

  static pw.Widget _buildDetailField(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            color: isHighlighted ? PdfColor.fromHex('1E4FD8') : PdfColors.black,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 8.5 : 7.5,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? (isHeader ? PdfColor.fromHex('1E4FD8') : PdfColors.black),
        ),
      ),
    );
  }
}
