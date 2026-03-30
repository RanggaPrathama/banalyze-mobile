import 'package:flutter/material.dart';
import 'package:banalyze/core/constants/app_colors.dart';
import 'package:banalyze/shared/models/article_model.dart';

class ArticleCard extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback onTap;

  const ArticleCard({super.key, required this.article, required this.onTap});

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'storage':
        return Icons.kitchen_rounded;
      case 'ripening':
        return Icons.timelapse_rounded;
      case 'recipes':
        return Icons.restaurant_rounded;
      case 'harvest':
        return Icons.agriculture_rounded;
      case 'edukasi':
        return Icons.school_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  Color _categoryColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (e) {
      // Ignore parse error and return default
    }
    return AppColors.primary;
  }

  String _getSubtitle() {
    final text = article.content.replaceAll('\n', ' ');
    if (text.length > 80) {
      return '${text.substring(0, 80)}...';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(article.category.colorHex);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.accent;
    final subtitleColor = isDark
        ? AppColors.darkTextSecondary
        : Colors.grey.shade600;
    final metaColor = isDark ? AppColors.darkTextHint : Colors.grey.shade400;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail or Category icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  image: article.thumbnailUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(article.thumbnailUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: article.thumbnailUrl.isEmpty
                    ? Icon(
                        _categoryIcon(article.category.name),
                        color: color,
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category + read time
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            article.category.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: metaColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${article.readTimeMinutes} min',
                          style: TextStyle(fontSize: 11, color: metaColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSubtitle(),
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
}
