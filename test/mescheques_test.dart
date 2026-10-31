import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mescheques/models/check.dart';
import 'package:mescheques/models/check_filter.dart';
import 'package:mescheques/models/person.dart';
import 'package:mescheques/utils/bidi_helper.dart';
import 'package:mescheques/utils/formatters.dart';
import 'package:mescheques/utils/text_normalizer.dart';
import 'package:mescheques/utils/validators.dart';

void main() {
  group('TextNormalizer tests (Arabic & French normalization)', () {
    test('removes tashkeel and tatweel', () {
      expect(TextNormalizer.normalize('مُحَمَّد'), 'محمد');
      expect(TextNormalizer.normalize('أحــــمد'), 'احمد');
    });

    test('unifies alif variants to plain alif', () {
      expect(TextNormalizer.normalize('أحمد'), 'احمد');
      expect(TextNormalizer.normalize('إبراهيم'), 'ابراهيم');
      expect(TextNormalizer.normalize('آدم'), 'ادم');
      expect(TextNormalizer.normalize('ٱبن'), 'ابن');
    });

    test('normalizes ta marbuta, alif maqsura, and hamzas', () {
      expect(TextNormalizer.normalize('فاطمة'), 'فاطمه');
      expect(TextNormalizer.normalize('موسى'), 'موسي');
      expect(TextNormalizer.normalize('مؤمن'), 'مومن');
      expect(TextNormalizer.normalize('رئيس'), 'رييس');
    });

    test('converts Arabic-Indic digits to Latin digits', () {
      expect(TextNormalizer.normalize('٢٥٠٠'), '2500');
      expect(TextNormalizer.normalize('٠١٢٣٤٥٦٧٨٩'), '0123456789');
    });

    test('strips French accents and normalizes case', () {
      expect(TextNormalizer.normalize('Hélène'), 'helene');
      expect(TextNormalizer.normalize('Aït Ali'), 'ait ali');
      expect(TextNormalizer.normalize('François'), 'francois');
    });

    test('matches normalized names across spellings', () {
      final name1 = TextNormalizer.normalize('أحمد آيت علي');
      final name2 = TextNormalizer.normalize('احمد ايت علي');
      expect(name1, equals(name2));
    });
  });

  group('BidiHelper tests', () {
    test('detects Arabic text as RTL', () {
      expect(BidiHelper.detectDirection('أحمد'), TextDirection.rtl);
      expect(BidiHelper.detectDirection('شركة الأمل'), TextDirection.rtl);
    });

    test('detects Latin text as LTR', () {
      expect(BidiHelper.detectDirection('Ahmed'), TextDirection.ltr);
      expect(BidiHelper.detectDirection('Ste Casablanca'), TextDirection.ltr);
    });

    test('detects empty and numeric text as LTR', () {
      expect(BidiHelper.detectDirection(''), TextDirection.ltr);
      expect(BidiHelper.detectDirection('12345'), TextDirection.ltr);
    });
  });

  group('Formatters tests', () {
    test('formatAmount formats Moroccan Dirham in French and Arabic', () {
      expect(Formatters.formatAmount(250000, isArabic: false), '2 500,00 DH');
      expect(Formatters.formatAmount(120000, showDecimals: false, isArabic: false), '1 200 DH');
      expect(Formatters.formatAmount(125050, showDecimals: false, isArabic: false), '1 250,50 DH');

      // Arabic formatting with Moroccan Dirham symbol
      expect(Formatters.formatAmount(250000, isArabic: true), '2 500,00 د.م.');
      expect(Formatters.formatAmount(120000, showDecimals: false, isArabic: true), '1 200 د.م.');
    });

    test('parseAmountToCents converts inputs to integer cents including Arabic-Indic digits', () {
      expect(Formatters.parseAmountToCents('2500'), 250000);
      expect(Formatters.parseAmountToCents('2500.50'), 250050);
      expect(Formatters.parseAmountToCents('2 500,75'), 250075);
      // Arabic-Indic numerals and Arabic decimal comma
      expect(Formatters.parseAmountToCents('٢٥٠٠'), 250000);
      expect(Formatters.parseAmountToCents('٢٥٠٠٫٥٠'), 250050);

      expect(Formatters.parseAmountToCents(''), isNull);
      expect(Formatters.parseAmountToCents('abc'), isNull);
      expect(Formatters.parseAmountToCents('-50'), isNull);
    });

    test('formatDate converts ISO 8601 to display format in French and Arabic', () {
      expect(Formatters.formatDate('2026-08-20', isArabic: false), '20/08/2026');
      expect(Formatters.formatDate('2026-08-20', isArabic: true), contains('2026'));
      expect(Formatters.formatDate(null), '-');
    });

    test('daysRemainingInTrash calculates 15-day retention correctly', () {
      final now = DateTime.now();
      final tenDaysAgo = now.subtract(const Duration(days: 10));
      expect(Formatters.daysRemainingInTrash(tenDaysAgo.toIso8601String()), 5);

      final sixteenDaysAgo = now.subtract(const Duration(days: 16));
      expect(Formatters.daysRemainingInTrash(sixteenDaysAgo.toIso8601String()), 0);
    });
  });

  group('Validators tests', () {
    test('validateRequired validates mandatory fields', () {
      expect(Validators.validateRequired('', 'Émetteur'), 'Émetteur est obligatoire');
      expect(Validators.validateRequired('Ahmed', 'Émetteur'), isNull);
      expect(
        Validators.validateRequired('', 'Émetteur', customError: 'الحقل إلزامي'),
        'الحقل إلزامي',
      );
    });

    test('validateAmount validates positive amount', () {
      expect(Validators.validateAmount(''), isNotNull);
      expect(Validators.validateAmount('0'), isNotNull);
      expect(Validators.validateAmount('2500'), isNull);
      expect(Validators.validateAmount('٢٥٠٠'), isNull); // Arabic-indic valid
    });

    test('validatePaymentDate ensures payment date is on or after reception date', () {
      final invalid = Validators.validatePaymentDate(
        paymentDateIso: '2026-08-15',
        receivedDateIso: '2026-08-18',
        hasPaidTo: true,
      );
      expect(invalid, isNotNull);

      final valid = Validators.validatePaymentDate(
        paymentDateIso: '2026-08-22',
        receivedDateIso: '2026-08-18',
        hasPaidTo: true,
      );
      expect(valid, isNull);
    });
  });

  group('Models & Logic tests', () {
    test('Person model computes normalized name', () {
      final p = Person(name: 'أحمد آيت علي', createdAt: '2026-08-18');
      expect(p.name, 'أحمد آيت علي');
      expect(p.nameNormalized, 'احمد ايت علي');
    });

    test('Check status is correctly derived from paidToId', () {
      final stockCheck = Check(
        id: 1,
        checkNumber: 'CHQ-001',
        amountCents: 100000,
        checkDate: '2026-08-20',
        receivedDate: '2026-08-18',
        giverId: 1,
        paidToId: null,
        paidDate: null,
        createdAt: '2026-08-18T10:00:00',
        updatedAt: '2026-08-18T10:00:00',
      );

      expect(stockCheck.isInStock, isTrue);
      expect(stockCheck.isUsed, isFalse);

      final usedCheck = stockCheck.copyWith(
        paidToId: () => 2,
        paidDate: () => '2026-08-22',
      );

      expect(usedCheck.isInStock, isFalse);
      expect(usedCheck.isUsed, isTrue);
    });

    test('CheckFilter active filters count', () {
      var filter = const CheckFilter();
      expect(filter.activeFiltersCount, 0);

      filter = filter.copyWith(
        status: CheckStatusFilter.stock,
        minAmountCents: () => 100000,
      );
      expect(filter.activeFiltersCount, 2);
    });
  });
}
