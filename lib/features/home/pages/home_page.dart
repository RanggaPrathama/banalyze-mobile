import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:banalyze/core/constants/app_colors.dart';
import 'package:banalyze/core/constants/app_strings.dart';
import 'package:banalyze/features/home/providers/home_provider.dart';
import 'package:banalyze/features/home/widgets/home_header.dart';
import 'package:banalyze/features/home/widgets/scan_banner.dart';
import 'package:banalyze/features/home/widgets/ripeness_card.dart';
import 'package:banalyze/features/home/widgets/scan_item.dart';
import 'package:banalyze/features/home/widgets/weekly_summary.dart';
import 'package:banalyze/shared/models/scan_history.dart';
import 'package:banalyze/router/app_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeProvider(),
      child: const _HomeBody(),
    );
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody();

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Converts a DateTime to a relative time string.
  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradientColors = isDark
        ? const [
            AppColors.darkGradientStart,
            AppColors.darkGradientMid,
            AppColors.darkGradientEnd,
          ]
        : const [
            AppColors.gradientStart,
            AppColors.gradientMid,
            AppColors.gradientEnd,
          ];

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),

          // Scrollable content
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await Future.wait([
                  home.loadRecentScans(),
                  home.loadRecentArticles(),
                ]);
              },
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 96, 20, 100),
                children: [
                  // Scan banner
                  const ScanBanner(),
                  const SizedBox(height: 28),

                  // Ripeness Guide
                  _buildSectionHeader(context, title: AppStrings.ripenessGuide),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 195,
                    child: home.recentArticles.isEmpty
                        ? ListView.separated(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: 3,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, __) => const RipenessCard(
                              label: '...',
                              subtitle: '',
                              stageLabel: '',
                              stageColor: AppColors.primary,
                              isLoading: true,
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: home.recentArticles.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final article = home.recentArticles[index];
                              return RipenessCard(
                                label: article.title,
                                subtitle: article.content.length > 60
                                    ? '${article.content.substring(0, 60)}...'
                                    : article.content,
                                stageLabel: article.category.name.toUpperCase(),
                                stageColor: _parseCategoryColor(
                                  article.category.colorHex,
                                ),
                                thumbnailUrl: article.thumbnailUrl,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRouter.articleDetail,
                                  arguments: article.id,
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 28),

                  // Weekly Summary
                  const WeeklySummary(),
                  const SizedBox(height: 28),

                  // Recent Scans
                  Text(
                    AppStrings.recentScans,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (home.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  else if (home.recentScans.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No scans yet. Tap Scan to start!',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextHint
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                    )
                  else
                    ...home.recentScans.map(
                      (scan) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ScanItem(
                          label: scan.ripeness.label,
                          subtitle: _relativeTime(scan.dateTime),
                          statusColor: scan.ripeness.color,
                          statusIcon: _ripenessIcon(scan.ripeness),
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRouter.scanDetail, arguments: scan.id),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Floating pinned header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _SliverHeader(isDark: isDark, scrollOffset: _scrollOffset),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? actionLabel,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Text(
                actionLabel ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: subtextColor,
                ),
              ),
              const SizedBox(width: 2),
              //  Icon(Icons.chevron_right, size: 16, color: subtextColor),
            ],
          ),
        ),
      ],
    );
  }

  IconData _ripenessIcon(RipenessLevel level) {
    switch (level) {
      case RipenessLevel.unripe:
        return Icons.arrow_upward_rounded;
      case RipenessLevel.partiallyRipe:
        return Icons.arrow_forward_rounded;
      case RipenessLevel.ripe:
        return Icons.check_circle_rounded;
      case RipenessLevel.overripe:
        return Icons.warning_amber_rounded;
    }
  }

  Color _parseCategoryColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
      if (hex.length == 8) return Color(int.parse(hex, radix: 16));
    } catch (_) {}
    return AppColors.primary;
  }
}

/// Sticky header that fades in background + blur when user scrolls down.
class _SliverHeader extends StatelessWidget {
  final bool isDark;
  final double scrollOffset;

  const _SliverHeader({required this.isDark, this.scrollOffset = 0});

  @override
  Widget build(BuildContext context) {
    // Fade in over the first 60px of scroll
    final t = (scrollOffset / 60.0).clamp(0.0, 1.0);
    final bgColor = isDark
        ? AppColors.darkGradientStart
        : AppColors.gradientStart;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: t),
        border: Border(
          bottom: BorderSide(
            color: (isDark ? AppColors.darkBorder : AppColors.border)
                .withValues(alpha: t * 0.6),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: const HomeHeader(),
        ),
      ),
    );
  }
}
