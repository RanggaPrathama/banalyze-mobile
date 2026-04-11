import 'package:dio/dio.dart';
import 'package:banalyze/core/network/dio_interceptor.dart';
import 'constants/app_url.dart';

const networkTimeout = Duration(seconds: 20);

final Dio apiClient = Dio(
  BaseOptions(
    baseUrl: AppUrl.apiBaseUrl,
    connectTimeout: networkTimeout,
    receiveTimeout: networkTimeout,
    sendTimeout: networkTimeout,
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ),
);

void setupDioInterceptors() => attachDioInterceptors(apiClient);
