import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:banalyze/shared/models/article_model.dart';
import 'package:banalyze/shared/models/scan_history.dart';
import 'package:banalyze/features/history/repositories/history_repository.dart';

class WeeklyBarData {
  final String day;
  final double value; // 0.0 – 1.0 normalized height

  const WeeklyBarData({required this.day, required this.value});
}

class HomeProvider extends ChangeNotifier {
  final HistoryRepository _historyRepository = HistoryRepository();

  bool _isLoading = false;
  List<ScanHistory> _recentScans = [];
  List<ArticleModel> _recentArticles = [];

  bool get isLoading => _isLoading;
  List<ScanHistory> get recentScans => _recentScans;
  List<ArticleModel> get recentArticles => _recentArticles;

  // ── Weekly summary stats
  /// Bar chart data — normalized heights per day of the week.
  List<WeeklyBarData> get weeklyBars {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final counts = List<int>.filled(7, 0);

    for (final scan in _recentScans) {
      // weekday: 1=Mon … 7=Sun
      final idx = scan.dateTime.weekday - 1;
      counts[idx]++;
    }

    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) {
      return days.map((d) => WeeklyBarData(day: d, value: 0)).toList();
    }

    return List.generate(
      7,
      (i) => WeeklyBarData(day: days[i], value: counts[i] / maxCount),
    );
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }

  int get totalScans => _recentScans.length;

  String get avgQuality {
    if (_recentScans.isEmpty) return '—';
    final avg =
        _recentScans.map((s) => s.confidence).reduce((a, b) => a + b) /
        _recentScans.length;
    return '${(avg * 100).round()}%';
  }

  String get bestDay {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final counts = List<int>.filled(7, 0);
    for (final scan in _recentScans) {
      counts[scan.dateTime.weekday - 1]++;
    }
    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) return '—';
    return days[counts.indexOf(maxCount)];
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  HomeProvider() {
    // Equivalent to initState — runs once when provider is created.
    // Both calls run concurrently for faster load.
    loadRecentScans();
    loadRecentArticles();
  }

  Future<void> loadRecentScans() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _historyRepository.getHistory(paginate: 10);
      _recentScans = result.items;
    } catch (e) {
      debugPrint('Home load recent scans error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addScan(ScanHistory scan) {
    _recentScans.insert(0, scan);
    notifyListeners();
  }

  Future<void> loadRecentArticles() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('articles')
          .where('status', isEqualTo: 'published')
          .orderBy('published_at', descending: true)
          .limit(5)
          .get();

      _recentArticles = snapshot.docs
          .map((doc) => ArticleModel.fromFirestore(doc))
          .toList();
      notifyListeners();
    } catch (_) {
      // Silently fail — articles are non-critical on home page
    }
  }
}
