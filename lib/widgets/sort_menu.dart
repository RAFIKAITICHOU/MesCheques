import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/check_filter.dart';
import '../providers/locale_provider.dart';
import '../utils/constants.dart';

class SortBottomSheet extends StatelessWidget {
  final CheckSortOption currentSort;
  final ValueChanged<CheckSortOption> onSelectSort;

  const SortBottomSheet({
    super.key,
    required this.currentSort,
    required this.onSelectSort,
  });

  static Future<void> show(
    BuildContext context, {
    required CheckSortOption currentSort,
    required ValueChanged<CheckSortOption> onSelectSort,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SortBottomSheet(
        currentSort: currentSort,
        onSelectSort: onSelectSort,
      ),
    );
  }

  String _getLocalizedSortLabel(CheckSortOption option, bool isArabic) {
    if (!isArabic) return option.label;

    switch (option) {
      case CheckSortOption.lifo:
        return 'الأحدث إضافة (LIFO)';
      case CheckSortOption.fifo:
        return 'الأقدم إضافة';
      case CheckSortOption.giverNameAsc:
        return 'اسم المسلِّم (أ ← ي)';
      case CheckSortOption.giverNameDesc:
        return 'اسم المسلِّم (ي ← أ)';
      case CheckSortOption.amountDesc:
        return 'المبلغ (من الأعلى للأدنى)';
      case CheckSortOption.amountAsc:
        return 'المبلغ (من الأدنى للأعلى)';
      case CheckSortOption.checkDateDesc:
        return 'تاريخ الشيك (الأحدث)';
      case CheckSortOption.checkDateAsc:
        return 'تاريخ الشيك (الأقدم)';
      case CheckSortOption.receivedDateDesc:
        return 'تاريخ الاستلام (الأحدث)';
      case CheckSortOption.receivedDateAsc:
        return 'تاريخ الاستلام (الأقدم)';
      case CheckSortOption.numberAsc:
        return 'رقم الشيك (تصاعدي)';
      case CheckSortOption.numberDesc:
        return 'رقم الشيك (تنازلي)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.sort, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    l10n?.sortBy ?? 'Trier par',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: CheckSortOption.values.map((option) {
                  final isSelected = option == currentSort;
                  return ListTile(
                    dense: true,
                    title: Text(
                      _getLocalizedSortLabel(option, isArabic),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                        : null,
                    onTap: () {
                      onSelectSort(option);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
