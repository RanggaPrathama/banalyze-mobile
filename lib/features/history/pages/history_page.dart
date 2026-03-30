import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:banalyze/core/constants/app_colors.dart';
import 'package:banalyze/shared/models/scan_history.dart';
import 'package:banalyze/shared/widgets/paginated_list_view.dart';
import 'package:banalyze/features/history/providers/history_provider.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HistoryProvider()..loadInitial(),
      child: const _HistoryBody(),
    );
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text(
                      'Scan History',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.settings_outlined,
                      color: subtextColor,
                      size: 22,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: provider.updateSearch,
                  style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search by date or ripeness...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      color: hintColor,
                    ),
                    prefixIcon: Icon(Icons.search_rounded, color: hintColor),
                    filled: true,
                    fillColor: cardColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
              const SizedBox(height: 14),

              // Filter chips
              SizedBox(
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
              const SizedBox(height: 16),

              // Scan list with infinite scroll + pull-to-refresh
              Expanded(
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
                  itemBuilder: (context, entry, _) {
                    // entry.key == -1 means it's a section header (date label stored in title)
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
                    return _ScanHistoryTile(
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
            ],
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

class _ScanHistoryTile extends StatelessWidget {
  final ScanHistory scan;
  final bool isDark;
  final Color textColor;
  final Color subtextColor;
  final Color cardColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _ScanHistoryTile({
    required this.scan,
    required this.isDark,
    required this.textColor,
    required this.subtextColor,
    required this.cardColor,
    required this.borderColor,
    required this.onTap,
  });

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour12:$m $period';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // Ripeness indicator
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scan.ripeness.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🍌', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scan.ripeness.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          scan.ripeness.label,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: scan.ripeness.color,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(scan.confidence * 100).round()}%',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scan.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: subtextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatDate(scan.dateTime)} • ${_formatTime(scan.dateTime)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Confidence bar
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Text(
                    'Confident',
                    style: GoogleFonts.poppins(
                      fontSize: 7,
                      fontWeight: FontWeight.w500,
                      color: subtextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: scan.confidence,
                      backgroundColor: isDark
                          ? AppColors.darkBorder
                          : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(scan.ripeness.color),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
