import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:banalyze/core/constants/app_colors.dart';
import 'package:banalyze/features/article/providers/article_provider.dart';

class ArticleDetailPage extends StatelessWidget {
  final String articleId;

  const ArticleDetailPage({super.key, required this.articleId});

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonth(date.month)} ${date.year}';
  }

  String _getMonth(int month) {
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
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final article = context.read<ArticleProvider>().getArticleById(articleId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : Colors.white;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.accent;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : Colors.grey.shade500;
    final bodyColor = isDark
        ? AppColors.darkTextSecondary
        : Colors.grey.shade800;
    final dividerColor = isDark ? AppColors.darkBorder : Colors.grey.shade200;
    final appBarBg = isDark ? AppColors.darkSurface : AppColors.accent;

    if (article == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text('Not Found', style: TextStyle(color: textColor)),
          backgroundColor: appBarBg,
        ),
        body: Center(
          child: Text('Article not found.', style: TextStyle(color: textColor)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: appBarBg,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: article.thumbnailUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: article.thumbnailUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (_, __) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [AppColors.darkSurface, AppColors.darkCard]
                                : [AppColors.accent, const Color(0xFF3D4F51)],
                          ),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) =>
                          _buildHeaderFallback(isDark, article.category.name),
                    )
                  : _buildHeaderFallback(isDark, article.category.name),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              transform: Matrix4.translationValues(0, -24, 0),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.2,
                        ),
                        child: Text(
                          article.author.name.isNotEmpty
                              ? article.author.name[0]
                              : 'U',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article.author.name,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Text(
                            '${_formatDate(article.publishedAt)}  •  ${article.readTimeMinutes} min read',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: dividerColor),
                  const SizedBox(height: 16),
                  MarkdownBody(
                    data: article.content.replaceAll('\\n', '\n'),
                    styleSheet: MarkdownStyleSheet(
                      p: GoogleFonts.poppins(
                        fontSize: 15,
                        color: bodyColor,
                        height: 1.7,
                      ),
                      h1: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      h2: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      h3: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      strong: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      em: GoogleFonts.poppins(
                        fontStyle: FontStyle.italic,
                        color: bodyColor,
                      ),
                      listBullet: GoogleFonts.poppins(
                        fontSize: 15,
                        color: bodyColor,
                      ),
                      blockquote: GoogleFonts.poppins(
                        fontSize: 14,
                        color: subtextColor,
                        fontStyle: FontStyle.italic,
                      ),
                      code: GoogleFonts.sourceCodePro(
                        fontSize: 13,
                        backgroundColor: dividerColor,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: AppColors.primary, width: 4),
                        ),
                        color: AppColors.primary.withValues(alpha: 0.05),
                      ),
                    ),
                    softLineBreak: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Storage':
        return Icons.kitchen_rounded;
      case 'Ripening':
        return Icons.timelapse_rounded;
      case 'Recipes':
        return Icons.restaurant_rounded;
      case 'Harvest':
        return Icons.agriculture_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  Widget _buildHeaderFallback(bool isDark, String categoryName) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkSurface, AppColors.darkCard]
              : [AppColors.accent, const Color(0xFF3D4F51)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 40),
            Icon(
              _categoryIcon(categoryName),
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                categoryName,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
