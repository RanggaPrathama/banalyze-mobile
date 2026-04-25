import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:banalyze/core/constants/app_colors.dart';
import 'package:banalyze/shared/models/scan_history.dart';
import 'package:banalyze/shared/widgets/paginated_list_view.dart';
import 'package:banalyze/features/history/providers/history_provider.dart';
import 'package:banalyze/features/history/widgets/scan_summary_card.dart';
import 'package:banalyze/features/history/widgets/scan_history_tile.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HistoryBody();
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final hintColor = isDark ? AppColors.darkTextHint : AppColors.textHint;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    AppColors.darkGradientStart,
                    AppColors.darkGradientMid,
                    AppColors.darkGradientEnd,
                  ]
                : const [
                    AppColors.gradientStart,
                    AppColors.gradientMid,
                    AppColors.gradientEnd,
                  ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: PaginatedListView<MapEntry<int, ScanHistory>>(
            items: _buildFlatList(provider),
            isLoading: provider.isLoading,
            isLoadingMore: provider.isLoadingMore,
            hasMore: provider.hasMore,
            error: provider.error,
            onLoadMore: () => provider.loadMore(),
            onRefresh: () => provider.refresh(),
            emptyIcon: Icons.history_rounded,
            emptyTitle: 'No scan history yet',
            emptySubtitle: 'Your classification results will appear here',
            headerSlivers: [
              // Header + Summary + Search
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Text(
                        'Scan History',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: ScanSummaryCard(
                        ripeCount: provider.ripeCount,
                        partiallyRipeCount: provider.partiallyRipeCount,
                        overripeUnripeCount: provider.overripeUnripeCount,
                        totalCount: provider.thisWeekTotal,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: provider.updateSearch,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: textColor,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search history...',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: hintColor,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: hintColor,
                                ),
                                filled: true,
                                fillColor: cardColor,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDateRangePicker(
                                context: context,
                                initialDateRange:
                                    provider.startDate != null &&
                                        provider.endDate != null
                                    ? DateTimeRange(
                                        start: provider.startDate!,
                                        end: provider.endDate!,
                                      )
                                    : null,
                                firstDate: DateTime(2020),
                                lastDate: now,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: isDark
                                          ? const ColorScheme.dark(
                                              primary: AppColors.primary,
                                              onPrimary: Colors.white,
                                              surface: AppColors.darkCard,
                                              onSurface:
                                                  AppColors.darkTextPrimary,
                                            )
                                          : const ColorScheme.light(
                                              primary: AppColors.primary,
                                              onPrimary: Colors.white,
                                              surface: Colors.white,
                                              onSurface: AppColors.textPrimary,
                                            ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                provider.setDateRange(picked.start, picked.end);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (provider.startDate != null)
                                    ? AppColors.primary
                                    : cardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: (provider.startDate != null)
                                      ? AppColors.primary
                                      : borderColor,
                                ),
                                boxShadow: (provider.startDate != null)
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                Icons.calendar_month_rounded,
                                color: (provider.startDate != null)
                                    ? Colors.white
                                    : subtextColor,
                                size: 24,
                              ),
                            ),
                          ),
                          if (provider.startDate != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => provider.clearDateRange(),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.red.withValues(alpha: 0.15)
                                      : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Icon(
                                  Icons.clear_rounded,
                                  color: isDark ? Colors.redAccent : Colors.red,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              // Filter chips (horizontal scroll)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: provider.filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final f = provider.filters[index];
                      final selected = provider.selectedFilter == f;
                      final chipBg = isDark ? AppColors.darkCard : Colors.white;
                      final chipBorder = isDark
                          ? AppColors.darkBorder
                          : Colors.grey.shade300;
                      return GestureDetector(
                        onTap: () => provider.selectFilter(f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : chipBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected ? AppColors.primary : chipBorder,
                            ),
                          ),
                          child: Text(
                            f,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? AppColors.accent
                                  : (isDark
                                        ? AppColors.darkTextSecondary
                                        : Colors.grey.shade600),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
            itemBuilder: (context, entry, _) {
              final scan = entry.value;
              if (entry.key == -1) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 10),
                  child: Text(
                    scan.title,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: hintColor,
                      letterSpacing: 1,
                    ),
                  ),
                );
              }
              return ScanHistoryTile(
                scan: scan,
                isDark: isDark,
                textColor: textColor,
                subtextColor: subtextColor,
                cardColor: cardColor,
                borderColor: borderColor,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/scan-detail',
                    arguments: scan.id,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  /// Flatten grouped scans into a single list with section headers as entries.
  /// Section headers use key == -1, data items use key == index.
  List<MapEntry<int, ScanHistory>> _buildFlatList(HistoryProvider provider) {
    final grouped = provider.groupedScans;
    final flat = <MapEntry<int, ScanHistory>>[];

    for (final entry in grouped.entries) {
      // Section header: use a dummy ScanHistory with title = date label
      flat.add(
        MapEntry(
          -1,
          ScanHistory(
            id: '',
            title: entry.key,
            ripeness: RipenessLevel.unripe,
            confidence: 0,
            dateTime: DateTime.now(),
          ),
        ),
      );
      for (var i = 0; i < entry.value.length; i++) {
        flat.add(MapEntry(i, entry.value[i]));
      }
    }
    return flat;
  }
}
