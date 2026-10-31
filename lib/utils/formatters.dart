import 'package:intl/intl.dart';
import 'constants.dart';
import 'text_normalizer.dart';

class Formatters {
  static final NumberFormat _currencyFormatFr = NumberFormat('#,##0.00', 'fr_FR');
  static final NumberFormat _compactCurrencyFormatFr = NumberFormat('#,##0', 'fr_FR');
  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');

  static String _cleanSpaces(String text) {
    return text.replaceAll('\u202F', ' ').replaceAll('\u00A0', ' ');
  }

  /// Formats amount in cents to currency string with locale support
  /// e.g. 250000 -> "2 500,00 DH" in FR, or "2 500,00 د.م." in AR
  static String formatAmount(int amountCents, {bool showDecimals = true, bool isArabic = false}) {
    final double amount = amountCents / 100.0;
    final currencySymbol = isArabic ? 'د.م.' : AppConstants.currency;

    if (showDecimals || amountCents % 100 != 0) {
      final formatted = _cleanSpaces(_currencyFormatFr.format(amount));
      return isArabic ? '$formatted $currencySymbol' : '$formatted $currencySymbol';
    }
    final formatted = _cleanSpaces(_compactCurrencyFormatFr.format(amount));
    return isArabic ? '$formatted $currencySymbol' : '$formatted $currencySymbol';
  }

  /// Parses text input in DH or Arabic numerals (e.g. "2500.50", "2 500,50", "٢٥٠٠٫٥٠") to cents integer
  static int? parseAmountToCents(String input) {
    if (input.trim().isEmpty) return null;

    // Convert Arabic-Indic numerals & Arabic decimal separators first
    final converted = TextNormalizer.convertArabicDigits(input);
    final cleaned = converted.replaceAll(RegExp(r'[\s\u00A0\u202F]'), '').replaceAll(',', '.');
    final val = double.tryParse(cleaned);
    if (val == null || val <= 0) return null;
    return (val * 100).round();
  }

  /// Converts ISO 8601 string "yyyy-MM-dd" to display date, respecting language
  static String formatDate(String? isoDate, {String locale = 'fr', bool? isArabic}) {
    if (isoDate == null || isoDate.trim().isEmpty) return '-';
    try {
      final date = DateTime.parse(isoDate);
      final isAr = isArabic ?? locale.startsWith('ar');
      if (isAr) {
        // e.g. "20 غشت 2026"
        return DateFormat.yMMMd('ar_MA').format(date);
      }
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  /// Converts DateTime to ISO 8601 string "yyyy-MM-dd"
  static String toIsoDate(DateTime date) {
    return _isoDateFormat.format(date);
  }

  /// Parses ISO 8601 string "yyyy-MM-dd" to DateTime
  static DateTime? parseIsoDate(String? isoDate) {
    if (isoDate == null || isoDate.trim().isEmpty) return null;
    try {
      return DateTime.parse(isoDate);
    } catch (_) {
      return null;
    }
  }

  /// Calculates days remaining in trash (15 - days elapsed)
  static int daysRemainingInTrash(String? deletedAtIso) {
    if (deletedAtIso == null) return AppConstants.trashRetentionDays;
    try {
      final deletedDate = DateTime.parse(deletedAtIso);
      final daysElapsed = DateTime.now().difference(deletedDate).inDays;
      final remaining = AppConstants.trashRetentionDays - daysElapsed;
      return remaining > 0 ? remaining : 0;
    } catch (_) {
      return AppConstants.trashRetentionDays;
    }
  }
}
