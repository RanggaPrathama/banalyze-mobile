import 'package:banalyze/core/api_client.dart';
import 'package:banalyze/shared/models/scan_history.dart';
import 'package:flutter/foundation.dart';

class PaginatedHistory {
  final List<ScanHistory> items;
  final int currentPage;
  final int lastPage;
  final int total;

  const PaginatedHistory({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}

class HistoryRepository {
  Future<PaginatedHistory> getHistory({
    int page = 1,
    int paginate = 20,
    String? search,
    String orderBy = 'createdAt',
    String orderType = 'DESC',
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'paginate': paginate,
      'order_by': orderBy,
      'order_type': orderType,
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await apiClient.get(
      '/history-classify',
      queryParameters: queryParams,
    );

    debugPrint('History API response: ${response.data}');

    // API returns: { success, message, data: [...] } (flat list, no pagination)
    final rawData = response.data['data'];
    final List<dynamic> rawItems = rawData is List ? rawData : [];
    final items = rawItems.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      return ScanHistory.fromMap(map);
    }).toList();

    // No server-side pagination info — return all items as single page
    return PaginatedHistory(
      items: items,
      currentPage: 1,
      lastPage: 1,
      total: items.length,
    );
  }

  /// Fetch a single history entry by ID.
  Future<ScanHistory> getHistoryById(String historyId) async {
    final response = await apiClient.get('/history-classify/$historyId');
    final map = Map<String, dynamic>.from(response.data['data'] as Map);
    return ScanHistory.fromMap(map);
  }
}
