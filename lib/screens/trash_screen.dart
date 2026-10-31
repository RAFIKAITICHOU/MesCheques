import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/check.dart';
import '../providers/checks_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/bidi_helper.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  Future<void> _restoreCheck(BuildContext context, CheckWithNames item) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ChecksProvider>();
    try {
      await provider.restoreCheck(item.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.checkRestored(item.checkNumber))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.inStock),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.cannotRestoreTitle)),
              ],
            ),
            content: Text(
              e.toString().replaceAll('Exception: ', '').replaceAll('StateError: ', ''),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.understood),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _hardDeleteCheck(BuildContext context, CheckWithNames item, bool isArabic) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.hardDeleteTitle),
        content: Text(
          l10n.hardDeleteDesc(
            item.checkNumber,
            Formatters.formatAmount(item.amountCents, isArabic: isArabic),
          ),
        ),
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

    if (confirm == true && context.mounted) {
      final provider = context.read<ChecksProvider>();
      await provider.hardDeleteCheck(item.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.checkDeletedPerm)),
        );
      }
    }
  }

  Future<void> _emptyTrash(BuildContext context, ChecksProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.emptyTrashTitle),
        content: Text(l10n.emptyTrashDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(l10n.emptyTrashAction),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await provider.emptyTrash();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.trashCleared)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();
    final isArabic = localeProvider.isArabic;

    return Consumer<ChecksProvider>(
      builder: (context, provider, child) {
        final trash = provider.trashChecks;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.trash),
            actions: [
              if (trash.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _emptyTrash(context, provider),
                  icon: const Icon(Icons.delete_forever, color: AppColors.danger, size: 18),
                  label: Text(
                    l10n.emptyTrash,
                    style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Info Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppColors.primaryLight,
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.trashBanner,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: trash.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: AppColors.divider,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  size: 48,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.trashEmpty,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: trash.length,
                          itemBuilder: (context, index) {
                            final item = trash[index];
                            final daysRemaining = Formatters.daysRemainingInTrash(item.deletedAt);

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Giver & Amount
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Directionality(
                                            textDirection: BidiHelper.detectDirection(item.giverName),
                                            child: Text(
                                              item.giverName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Directionality(
                                          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                          child: Text(
                                            Formatters.formatAmount(item.amountCents, isArabic: isArabic),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.danger,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),

                                    // Row 2: Check number & deletion date
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.divider,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Directionality(
                                            textDirection: TextDirection.ltr,
                                            child: Text(
                                              item.checkNumber,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontFamily: 'monospace',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          l10n.deletedOn(
                                            Formatters.formatDate(item.deletedAt, isArabic: isArabic),
                                          ),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Row 3: Days remaining badge & Actions
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.inStockBg,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.hourglass_bottom, size: 13, color: AppColors.inStock),
                                              const SizedBox(width: 4),
                                              Text(
                                                l10n.trashRemaining(daysRemaining),
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.inStock,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: () => _restoreCheck(context, item),
                                              icon: const Icon(Icons.restore, size: 16),
                                              label: Text(l10n.restore, style: const TextStyle(fontSize: 12.5)),
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.delete_forever, color: AppColors.danger, size: 20),
                                              tooltip: l10n.deletePermanently,
                                              onPressed: () => _hardDeleteCheck(context, item, isArabic),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
