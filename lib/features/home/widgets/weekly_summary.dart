import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:banalyze/core/constants/app_colors.dart';
import 'package:banalyze/features/home/providers/home_provider.dart';

/// Weekly summary card with bar chart and stats.
class WeeklySummary extends StatelessWidget {
  const WeeklySummary({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final badgeBg = isDark
        ? AppColors.primary.withValues(alpha: 0.15)
        : AppColors.primarySoft;
    final badgeText = isDark ? AppColors.primary : AppColors.primaryDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Summary',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final provider = context.read<HomeProvider>();
                  final now = DateTime.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    initialDateRange: DateTimeRange(
                      start:
                          provider.startDate ??
                          now.subtract(const Duration(days: 6)),
                      end: provider.endDate ?? now,
                    ),
                    firstDate: DateTime(2020),
                    lastDate: now,
                  );
                  if (picked != null) {
                    provider.setDateRange(picked.start, picked.end);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: badgeText),
                      const SizedBox(width: 4),
                      Builder(
                        builder: (context) {
                          final provider = context.watch<HomeProvider>();
                          final isDefault =
                              provider.startDate == null &&
                              provider.endDate == null;
                          String labelText = 'This Week';
                          if (!isDefault) {
                            final startStr =
                                "${provider.startDate!.day}/${provider.startDate!.month}";
                            final endStr =
                                "${provider.endDate!.day}/${provider.endDate!.month}";
                            labelText = "$startStr - $endStr";
                          }
                          return Text(
                            labelText,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: badgeText,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_drop_down, size: 14, color: badgeText),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Bar chart
          _BarChart(bars: context.watch<HomeProvider>().weeklyBars),
          const SizedBox(height: 20),
          // Stats row
          Builder(
            builder: (context) {
              final p = context.watch<HomeProvider>();
              return Row(
                children: [
                  _StatItem(value: p.totalScans.toString(), label: 'SCANS'),
                  _StatItem(value: p.avgQuality, label: 'AVG QUALITY'),
                  _StatItem(value: p.bestDay, label: 'BEST DAY'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<WeeklyBarData> bars;

  const _BarChart({required this.bars});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? AppColors.darkTextHint : AppColors.textHint;
    final barColor = isDark
        ? AppColors.primary.withValues(alpha: 0.3)
        : AppColors.primaryLight;

    final maxVal = bars.map((b) => b.value).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((bar) {
          final isHighest = bar.value == maxVal;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: FractionallySizedBox(
                    heightFactor: bar.value,
                    child: Container(
                      width: 18,
                      decoration: BoxDecoration(
                        color: isHighest ? AppColors.primary : barColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  bar.day,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: hintColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final hintColor = isDark ? AppColors.darkTextHint : AppColors.textHint;

    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: hintColor,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
