import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:banalyze/core/constants/app_colors.dart';

/// A reusable paginated list with pull-to-refresh and auto-load-more.
///
/// Usage:
/// ```dart
/// PaginatedListView<MyItem>(
///   items: provider.items,
///   isLoading: provider.isLoading,
///   hasMore: provider.hasMore,
///   onLoadMore: () => provider.loadMore(),
///   onRefresh: () => provider.refresh(),
///   itemBuilder: (context, item, index) => MyItemTile(item: item),
///   emptyIcon: Icons.inbox,
///   emptyTitle: 'No items',
///   emptySubtitle: 'Pull to refresh',
/// )
/// ```
class PaginatedListView<T> extends StatefulWidget {
  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final List<Widget>? headerSlivers;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.isLoading,
    this.isLoadingMore = false,
    required this.hasMore,
    this.error,
    required this.onLoadMore,
    required this.onRefresh,
    required this.itemBuilder,
    this.padding,
    this.emptyIcon = Icons.inbox_rounded,
    this.emptyTitle = 'No data',
    this.emptySubtitle = 'Pull down to refresh',
    this.headerSlivers,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!widget.isLoading && !widget.isLoadingMore && widget.hasMore) {
        widget.onLoadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? AppColors.darkTextHint : AppColors.textHint;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    // Initial loading
    if (widget.isLoading && widget.items.isEmpty) {
      return CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          if (widget.headerSlivers != null) ...widget.headerSlivers!,
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading data...',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: hintColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Error with no data
    if (widget.error != null && widget.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (widget.headerSlivers != null) ...widget.headerSlivers!,
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 64, color: hintColor),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: subtextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.error!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: hintColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: widget.onRefresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(
                          'Retry',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (widget.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (widget.headerSlivers != null) ...widget.headerSlivers!,
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.emptyIcon, size: 64, color: hintColor),
                    const SizedBox(height: 16),
                    Text(
                      widget.emptyTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: subtextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.emptySubtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Data list with load-more
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.primary,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (widget.headerSlivers != null) ...widget.headerSlivers!,
          SliverPadding(
            padding:
                widget.padding ?? const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Render load more indicator at the bottom
                  if (index == widget.items.length) {
                    if (widget.isLoadingMore) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    } else if (!widget.hasMore && widget.items.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'You have reached the end.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: hintColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox(height: 24); // Spacing for end empty
                  }

                  return widget.itemBuilder(
                    context,
                    widget.items[index],
                    index,
                  );
                },
                childCount:
                    widget.items.length + 1, // +1 for the load-more indicator
              ),
            ),
          ),
        ],
      ),
    );
  }
} // End of PaginatedListViewState
