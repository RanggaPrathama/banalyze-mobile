import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:banalyze/shared/models/scan_history.dart';
import 'package:banalyze/features/history/repositories/history_repository.dart';

class HistoryProvider extends ChangeNotifier {
  final HistoryRepository _repository = HistoryRepository();

  String _selectedFilter = 'All Scans';
  String _searchQuery = '';
  List<ScanHistory> _scans = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;

  // Debounce timer for search
  Timer? _searchDebounce;

  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;
  List<ScanHistory> get scans => _scans;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _currentPage < _lastPage;

  List<String> get filters => const [
    'All Scans',
    'Partially Ripe',
    'Ripe',
    'Overripe',
  ];

  /// Call once on init to load first page.
  Future<void> loadInitial() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getHistory(
        page: 1,
        search: _buildSearchQuery(),
      );
      _scans = result.items;
      _currentPage = result.currentPage;
      _lastPage = result.lastPage;
    } catch (e) {
      _error = 'Gagal memuat riwayat.';
      debugPrint('History load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load next page (called by PaginatedListView).
  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _repository.getHistory(
        page: _currentPage + 1,
        search: _buildSearchQuery(),
      );
      _scans.addAll(result.items);
      _currentPage = result.currentPage;
      _lastPage = result.lastPage;
    } catch (e) {
      debugPrint('History load more error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Pull-to-refresh: reset and reload from page 1.
  Future<void> refresh() async {
    _currentPage = 1;
    _lastPage = 1;
    _error = null;

    try {
      final result = await _repository.getHistory(
        page: 1,
        search: _buildSearchQuery(),
      );
      _scans = result.items;
      _currentPage = result.currentPage;
      _lastPage = result.lastPage;
    } catch (e) {
      _error = 'Gagal memuat riwayat.';
      debugPrint('History refresh error: $e');
    }
    notifyListeners();
  }

  void selectFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
    loadInitial();
  }

  void updateSearch(String query) {
    _searchQuery = query;
    // Debounce: wait 500ms after user stops typing
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      loadInitial();
    });
  }

  /// Build search query string combining filter + text search.
  String? _buildSearchQuery() {
    final parts = <String>[];

    // Add text search
    if (_searchQuery.isNotEmpty) {
      parts.add(_searchQuery);
    }

    // Add filter as search term (API-side filtering)
    if (_selectedFilter != 'All Scans') {
      parts.add(_selectedFilter);
    }

    return parts.isEmpty ? null : parts.join(' ');
  }

  /// Group current scans by date label.
  Map<String, List<ScanHistory>> get groupedScans {
    final Map<String, List<ScanHistory>> grouped = {};

    for (final scan in _scans) {
      final now = DateTime.now();
      final diff = DateTime(now.year, now.month, now.day)
          .difference(
            DateTime(
              scan.dateTime.year,
              scan.dateTime.month,
              scan.dateTime.day,
            ),
          )
          .inDays;

      String label;
      if (diff == 0) {
        label = 'TODAY';
      } else if (diff == 1) {
        label = 'YESTERDAY';
      } else {
        label =
            '${scan.dateTime.month}/${scan.dateTime.day}/${scan.dateTime.year}';
      }

      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(scan);
    }

    return grouped;
  }

  ScanHistory? getScanById(String id) {
    try {
      return _scans.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Weekly Summary ────────────────────────────────────────────────────────

  List<ScanHistory> get _thisWeekScans {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return _scans.where((s) => s.dateTime.isAfter(start)).toList();
  }

  int get ripeCount =>
      _thisWeekScans.where((s) => s.ripeness == RipenessLevel.ripe).length;

  int get partiallyRipeCount => _thisWeekScans
      .where((s) => s.ripeness == RipenessLevel.partiallyRipe)
      .length;

  int get overripeUnripeCount => _thisWeekScans
      .where(
        (s) =>
            s.ripeness == RipenessLevel.overripe ||
            s.ripeness == RipenessLevel.unripe,
      )
      .length;

  int get thisWeekTotal => _thisWeekScans.length;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
