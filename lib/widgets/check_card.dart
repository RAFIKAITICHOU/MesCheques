import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/check.dart';
import '../providers/locale_provider.dart';
import '../services/image_service.dart';
import '../utils/bidi_helper.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'status_badge.dart';

class CheckCard extends StatelessWidget {
  final CheckWithNames item;
  final VoidCallback onTap;

  const CheckCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final localeCode = isArabic ? 'ar' : 'fr';

    final giverDirection = BidiHelper.detectDirection(
      item.giverName,
      defaultDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
    );

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading thumbnail or icon
              _buildLeadingImage(context),
              const SizedBox(width: 12),

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Giver Name & Amount
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.giverName,
                            textDirection: giverDirection,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Directionality(
                          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                          child: Text(
                            Formatters.formatAmount(item.amountCents, isArabic: isArabic),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Titulaire (Drawer) - only if different from giver
                    if (item.isDrawerDifferent) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${l10n?.drawer ?? "Titulaire"} : ${item.drawerName}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 6),

                    // Middle Row: Check Number and Check Date
                    Row(
                      children: [
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.checkNumber,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('·', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        const Icon(Icons.event_outlined, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          Formatters.formatDate(item.checkDate, locale: localeCode),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Bottom Row: Payment info / status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.receivedOn(Formatters.formatDate(item.receivedDate, locale: localeCode)) ??
                                    'Reçu le : ${Formatters.formatDate(item.receivedDate)}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              if (item.isUsed) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      isArabic ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                                      size: 12,
                                      color: AppColors.used,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        l10n?.paidToOn(
                                          item.paidToName ?? "-",
                                          Formatters.formatDate(item.paidDate, locale: localeCode),
                                        ) ??
                                            'Payé à ${item.paidToName ?? "-"} le ${Formatters.formatDate(item.paidDate)}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.used,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(isInStock: item.isInStock, isCompact: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingImage(BuildContext context) {
    if (item.primaryImageFileName != null && item.primaryImageFileName!.isNotEmpty) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
              color: Colors.grey.shade100,
            ),
            clipBehavior: Clip.antiAlias,
            child: FutureBuilder<Uint8List>(
              future: ImageService.instance.loadThumbnailBytes(item.primaryImageFileName!),
              builder: (ctx, snapshot) {
                if (snapshot.hasData) {
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                  );
                }
                return const Center(
                  child: Icon(Icons.image_outlined, size: 20, color: AppColors.textMuted),
                );
              },
            ),
          ),
          if (item.imageCount > 1)
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.imageCount}',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Default icon if no image
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.account_balance_wallet_outlined,
        color: AppColors.primary,
        size: 22,
      ),
    );
  }
}
