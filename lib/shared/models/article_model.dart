import 'package:cloud_firestore/cloud_firestore.dart';

class ArticleAuthor {
  final String name;
  final String avatarUrl;

  const ArticleAuthor({required this.name, required this.avatarUrl});

  factory ArticleAuthor.fromMap(Map<String, dynamic> map) {
    return ArticleAuthor(
      name: map['name'] as String? ?? 'Unknown Author',
      avatarUrl: map['avatar_url'] as String? ?? '',
    );
  }
}

class ArticleCategory {
  final String name;
  final String colorHex;

  const ArticleCategory({required this.name, required this.colorHex});

  factory ArticleCategory.fromMap(Map<String, dynamic> map) {
    return ArticleCategory(
      name: map['name'] as String? ?? 'General',
      colorHex: map['color'] as String? ?? '#000000',
    );
  }
}

class ArticleModel {
  final String id;
  final ArticleAuthor author;
  final ArticleCategory category;
  final String content;
  final DateTime publishedAt;
  final int readTimeMinutes;
  final String status;
  final String thumbnailUrl;
  final String title;

  const ArticleModel({
    required this.id,
    required this.author,
    required this.category,
    required this.content,
    required this.publishedAt,
    required this.readTimeMinutes,
    required this.status,
    required this.thumbnailUrl,
    required this.title,
  });

  factory ArticleModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};

    return ArticleModel(
      id: doc.id,
      author: ArticleAuthor.fromMap(
        map['author'] as Map<String, dynamic>? ?? {},
      ),
      category: ArticleCategory.fromMap(
        map['category'] as Map<String, dynamic>? ?? {},
      ),
      content: map['content'] as String? ?? '',
      publishedAt:
          (map['published_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readTimeMinutes: map['read_time_minutes'] as int? ?? 0,
      status: map['status'] as String? ?? 'draft',
      thumbnailUrl: map['thumbnail_url'] as String? ?? '',
      title: map['title'] as String? ?? 'Untitled',
    );
  }
}
