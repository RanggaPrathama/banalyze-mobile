import 'package:dio/dio.dart';
import 'package:banalyze/core/network/dio_interceptor.dart';
import './constants/api_url.dart';

final Dio apiClient = Dio(
  BaseOptions(
    baseUrl: AppUrl.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ),
);

void setupDioInterceptors() => attachDioInterceptors(apiClient);
