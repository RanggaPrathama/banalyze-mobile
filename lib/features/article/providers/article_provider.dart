import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:banalyze/shared/models/article_model.dart';

class ArticleProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ArticleModel> _articles = [];
  bool _isLoading = false;
  String? _error;

  String _selectedCategory = 'All';
  String _searchQuery = '';

  List<ArticleModel> get articles => _articles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  // Derive categories dynamically from the articles
  List<String> get categories {
    final cats = {'All'};
    for (var article in _articles) {
      if (article.category.name.isNotEmpty) {
        cats.add(article.category.name);
      }
    }
    return cats.toList();
  }

  ArticleProvider() {
    fetchArticles();
  }

  Future<void> fetchArticles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('articles')
          .where('status', isEqualTo: 'published')
          .orderBy('published_at', descending: true)
          .get();

      _articles = snapshot.docs
          .map((doc) => ArticleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _error = 'Failed to load articles: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void updateSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<ArticleModel> get filteredArticles {
    return _articles.where((article) {
      final matchesCategory =
          _selectedCategory == 'All' ||
          article.category.name == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          article.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          article.content.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  ArticleModel? getArticleById(String id) {
    try {
      return _articles.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
