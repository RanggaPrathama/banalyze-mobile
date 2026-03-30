import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:banalyze/core/constants/app_colors.dart';
import 'package:banalyze/features/article/providers/article_provider.dart';
import 'package:banalyze/features/article/widgets/category_chip.dart';
import 'package:banalyze/features/article/widgets/article_card.dart';

class ArticleListPage extends StatelessWidget {
  const ArticleListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ArticleListBody();
  }
}

class _ArticleListBody extends StatelessWidget {
  const _ArticleListBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArticleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.accent;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : Colors.grey.shade600;
    final hintColor = isDark ? AppColors.darkTextHint : Colors.grey.shade400;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : Colors.grey.shade200;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Banana Guide 🍌',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Learn everything about bananas',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: provider.updateSearch,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search articles...',
                    hintStyle: TextStyle(color: hintColor),
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

              // Category chips
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: provider.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = provider.categories[index];
                    return CategoryChip(
                      label: cat,
                      isSelected: provider.selectedCategory == cat,
                      onTap: () => provider.selectCategory(cat),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Article list
              Expanded(
                child: _buildListContent(provider, hintColor, subtextColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListContent(
    ArticleProvider provider,
    Color hintColor,
    Color subtextColor,
  ) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load articles:\n${provider.error}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: subtextColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: provider.fetchArticles,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.filteredArticles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: hintColor),
            const SizedBox(height: 8),
            Text(
              'No articles found',
              style: TextStyle(fontSize: 15, color: subtextColor),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchArticles,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: provider.filteredArticles.length,
        itemBuilder: (context, index) {
          final article = provider.filteredArticles[index];
          return ArticleCard(
            article: article,
            onTap: () => Navigator.pushNamed(
              context,
              '/article-detail',
              arguments: article.id,
            ),
          );
        },
      ),
    );
  }
}
