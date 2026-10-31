import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/check_filter.dart';
import '../providers/locale_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class StatsHeader extends StatelessWidget {
  final CheckStats stats;

  const StatsHeader({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Total checks card
          Expanded(
            flex: 2,
            child: _buildStatCard(
              title: l10n?.total ?? 'Total',
              mainValue: '${stats.totalCount}',
              subValue: l10n?.checkCount(stats.totalCount) ?? '${stats.totalCount} chèques',
              icon: Icons.receipt_long_outlined,
              iconColor: AppColors.primary,
              bgColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          // Total Amount card
          Expanded(
            flex: 3,
            child: _buildStatCard(
              title: l10n?.totalAmount ?? 'Montant total',
              mainValue: Formatters.formatAmount(
                stats.totalAmountCents,
                showDecimals: false,
                isArabic: isArabic,
              ),
              subValue: stats.totalAmountCents > 0
                  ? (l10n?.checkCount(stats.totalCount) ?? '${stats.totalCount} chèques')
                  : (isArabic ? '0 د.م.' : '0 DH'),
              icon: Icons.account_balance_wallet_outlined,
              iconColor: AppColors.primaryDark,
              bgColor: Colors.white,
              isHighlight: true,
            ),
          ),
          const SizedBox(width: 8),
          // In Stock card
          Expanded(
            flex: 2,
            child: _buildStatCard(
              title: l10n?.inStock ?? 'En stock',
              mainValue: '${stats.inStockCount}',
              subValue: Formatters.formatAmount(
                stats.inStockAmountCents,
                showDecimals: false,
                isArabic: isArabic,
              ),
              icon: Icons.inventory_2_outlined,
              iconColor: AppColors.inStock,
              bgColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String mainValue,
    required String subValue,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight ? AppColors.primary.withValues(alpha: 0.25) : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 14, color: iconColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            mainValue,
            style: TextStyle(
              fontSize: isHighlight ? 14 : 16,
              fontWeight: FontWeight.w700,
              color: isHighlight ? AppColors.primary : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
