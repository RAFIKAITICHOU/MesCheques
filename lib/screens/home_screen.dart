import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/check_filter.dart';
import '../providers/checks_provider.dart';
import '../providers/locale_provider.dart';
import '../services/pdf_service.dart';
import '../utils/bidi_helper.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/check_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/sort_menu.dart';
import '../widgets/stats_header.dart';
import 'add_check_screen.dart';
import 'check_details_screen.dart';
import 'settings_screen.dart';
import 'trash_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _exportPdf(BuildContext context, ChecksProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.read<LocaleProvider>();

    if (provider.checks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noChecksToExport)),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.print_outlined, color: AppColors.primary),
              title: Text(l10n.printPdf),
              onTap: () {
                Navigator.pop(ctx);
                PdfService.printChecksList(
                  checks: provider.checks,
                  filter: provider.filter,
                  localeCode: localeProvider.locale.languageCode,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: AppColors.primary),
              title: Text(l10n.sharePdf),
              onTap: () {
                Navigator.pop(ctx);
                PdfService.shareChecksPdf(
                  checks: provider.checks,
                  filter: provider.filter,
                  localeCode: localeProvider.locale.languageCode,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();
    final isArabic = localeProvider.isArabic;

    return Consumer<ChecksProvider>(
      builder: (context, provider, child) {
        final trashCount = provider.trashChecks.length;
        final activeFiltersCount = provider.filter.activeFiltersCount;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.payments_outlined, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Text(l10n.appName),
              ],
            ),
            actions: [
              // Trash Icon Button with Badge
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.trash,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TrashScreen()),
                      );
                    },
                  ),
                  if (trashCount > 0)
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$trashCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              // Settings Icon Button
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: l10n.settings,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.refreshAll(),
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                // Stats Header
                SliverToBoxAdapter(
                  child: StatsHeader(stats: provider.stats),
                ),

                // Search Box
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: TextField(
                      controller: _searchController,
                      textDirection: BidiHelper.detectDirection(_searchController.text),
                      decoration: InputDecoration(
                        hintText: l10n.searchHint,
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) {
                        provider.setSearchQuery(val);
                        setState(() {});
                      },
                    ),
                  ),
                ),

                // Tabs / Status Segment
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        _buildStatusTab(
                          label: l10n.all,
                          count: provider.stats.totalCount,
                          isSelected: provider.filter.status == CheckStatusFilter.all,
                          onTap: () => provider.setStatusFilter(CheckStatusFilter.all),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusTab(
                          label: l10n.inStock,
                          count: provider.stats.inStockCount,
                          isSelected: provider.filter.status == CheckStatusFilter.stock,
                          color: AppColors.inStock,
                          onTap: () => provider.setStatusFilter(CheckStatusFilter.stock),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusTab(
                          label: l10n.used,
                          count: provider.stats.usedCount,
                          isSelected: provider.filter.status == CheckStatusFilter.used,
                          color: AppColors.used,
                          onTap: () => provider.setStatusFilter(CheckStatusFilter.used),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action Bar (Sort, Filter, PDF)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        // Sort Button
                        InkWell(
                          onTap: () {
                            SortBottomSheet.show(
                              context,
                              currentSort: provider.filter.sortOption,
                              onSelectSort: (newSort) => provider.setSortOption(newSort),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.swap_vert, size: 18, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  _shortSortLabel(provider.filter.sortOption, l10n),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Filters Button
                        InkWell(
                          onTap: () {
                            FilterBottomSheet.show(
                              context,
                              currentFilter: provider.filter,
                              onApply: (f) => provider.applyFilter(f),
                              onReset: () => provider.resetFilters(),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: activeFiltersCount > 0 ? AppColors.primaryLight : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: activeFiltersCount > 0 ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.tune,
                                  size: 18,
                                  color: activeFiltersCount > 0 ? AppColors.primary : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  activeFiltersCount > 0 ? '${l10n.filters} ($activeFiltersCount)' : l10n.filters,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: activeFiltersCount > 0 ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),

                        // PDF Export Button
                        ElevatedButton.icon(
                          onPressed: () => _exportPdf(context, provider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            elevation: 0,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                          label: Text(
                            l10n.exportPdf,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Active Filters Chips (if any)
                if (provider.filter.hasAdvancedFilters)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ActionChip(
                              label: Text(l10n.clearAll, style: const TextStyle(fontSize: 11)),
                              backgroundColor: AppColors.dangerBg,
                              labelStyle: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                              onPressed: () => provider.resetFilters(),
                              padding: EdgeInsets.zero,
                            ),
                            const SizedBox(width: 6),
                            if (provider.filter.minAmountCents != null)
                              _buildActiveFilterChip(
                                label: l10n.minAmountFilter(
                                  Formatters.formatAmount(provider.filter.minAmountCents!, isArabic: isArabic),
                                ),
                                onDeleted: () => provider.clearFilterMinAmount(),
                              ),
                            if (provider.filter.maxAmountCents != null)
                              _buildActiveFilterChip(
                                label: l10n.maxAmountFilter(
                                  Formatters.formatAmount(provider.filter.maxAmountCents!, isArabic: isArabic),
                                ),
                                onDeleted: () => provider.clearFilterMaxAmount(),
                              ),
                            if (provider.filter.checkDateFrom != null || provider.filter.checkDateTo != null)
                              _buildActiveFilterChip(
                                label: l10n.checkDateRangeFilter(
                                  Formatters.formatDate(provider.filter.checkDateFrom, isArabic: isArabic),
                                  Formatters.formatDate(provider.filter.checkDateTo, isArabic: isArabic),
                                ),
                                onDeleted: () => provider.clearFilterDateRange(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Checks List or Empty View
                if (provider.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.checks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context, provider, l10n),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 80, top: 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = provider.checks[index];
                          return CheckCard(
                            item: item,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CheckDetailsScreen(checkId: item.id!),
                                ),
                              );
                            },
                          );
                        },
                        childCount: provider.checks.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddCheckScreen()),
              );
            },
            icon: const Icon(Icons.add, size: 22),
            label: Text(l10n.newCheck, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildStatusTab({
    required String label,
    required int count,
    required bool isSelected,
    Color color = AppColors.primary,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
        backgroundColor: AppColors.primaryLight,
        deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.primary),
        onDeleted: onDeleted,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ChecksProvider provider, AppLocalizations l10n) {
    final hasFilter = provider.filter.hasAdvancedFilters ||
        provider.filter.searchQuery != null ||
        provider.filter.status != CheckStatusFilter.all;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 54,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilter ? l10n.noChecksFound : l10n.noChecksEmpty,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter ? l10n.noChecksFoundDesc : l10n.noChecksEmptyDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (hasFilter) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => provider.resetFilters(),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.resetFilters),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _shortSortLabel(CheckSortOption sort, AppLocalizations l10n) {
    switch (sort) {
      case CheckSortOption.lifo:
        return l10n.sortLifo;
      case CheckSortOption.fifo:
        return l10n.sortFifo;
      case CheckSortOption.amountDesc:
        return l10n.sortAmountDesc;
      case CheckSortOption.amountAsc:
        return l10n.sortAmountAsc;
      case CheckSortOption.checkDateDesc:
        return l10n.sortCheckDateDesc;
      case CheckSortOption.giverNameAsc:
        return l10n.sortNameAsc;
      default:
        return l10n.sort;
    }
  }
}
