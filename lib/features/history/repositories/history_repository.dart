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
    String? startDate,
    String? endDate,
    String? userId,
    String orderBy = 'createdAt',
    String orderType = 'DESC',
    bool noPagination = false,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'paginate': paginate,
      'order_by': orderBy,
      'order_type': orderType,
    };
    if (noPagination) {
      queryParams['no_pagination'] = true;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (startDate != null && startDate.isNotEmpty) {
      queryParams['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParams['end_date'] = endDate;
    }
    if (userId != null && userId.isNotEmpty) {
      queryParams['user_id'] = userId;
    }

    final response = await apiClient.get(
      '/history-classify',
      queryParameters: queryParams,
    );

    debugPrint('History API response Type: ${response.data.runtimeType}');

    // Try parsing conventional pagination metadata
    final body = response.data is Map ? response.data : {};

    // Sometimes API returns list wrapped in data.data or just data
    final dynamic rawData = body['data'];
    final List<dynamic> rawItems = (rawData is List)
        ? rawData
        : (rawData is Map && rawData['data'] is List)
        ? rawData['data']
        : [];

    final items = rawItems.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      return ScanHistory.fromMap(map);
    }).toList();

    int currentPage = page;
    int lastPage = page;
    int total = items.length;

    // Check if the response contains pagination fields
    if (body.containsKey('current_page')) {
      currentPage = body['current_page'] is int
          ? body['current_page']
          : int.tryParse(body['current_page'].toString()) ?? page;
    } else if (rawData is Map && rawData.containsKey('current_page')) {
      currentPage = rawData['current_page'] is int
          ? rawData['current_page']
          : int.tryParse(rawData['current_page'].toString()) ?? page;
    }

    if (body.containsKey('last_page')) {
      lastPage = body['last_page'] is int
          ? body['last_page']
          : int.tryParse(body['last_page'].toString()) ?? page;
    } else if (rawData is Map && rawData.containsKey('last_page')) {
      lastPage = rawData['last_page'] is int
          ? rawData['last_page']
          : int.tryParse(rawData['last_page'].toString()) ?? page;
    } else {
      // Fallback inference: if items length equals paginate limit, there might be a next page
      lastPage = items.length == paginate ? page + 1 : page;
    }

    if (body.containsKey('total')) {
      total = body['total'] is int
          ? body['total']
          : int.tryParse(body['total'].toString()) ?? total;
    } else if (rawData is Map && rawData.containsKey('total')) {
      total = rawData['total'] is int
          ? rawData['total']
          : int.tryParse(rawData['total'].toString()) ?? total;
    }

    return PaginatedHistory(
      items: items,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
    );
  }

  /// Fetch a single history entry by ID.
  Future<ScanHistory> getHistoryById(String historyId) async {
    final response = await apiClient.get('/history-classify/$historyId');
    final map = Map<String, dynamic>.from(response.data['data'] as Map);
    return ScanHistory.fromMap(map);
  }
}
