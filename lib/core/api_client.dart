// lib/core/network/api_client.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:banalyze/app.dart';
import 'package:banalyze/router/app_router.dart';
import 'package:banalyze/shared/widgets/app_snackbar.dart';
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

// Helper function to force logout anywhere in the app
Future<void> _performLogout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('access_token');
  await prefs.remove('refresh_token');

  // Clear focus and navigate back to login
  FocusManager.instance.primaryFocus?.unfocus();
  navigatorKey.currentState?.pushNamedAndRemoveUntil(
    AppRouter.login,
    (route) => false,
  );

  // Show snackbar after navigation
  Future.delayed(const Duration(milliseconds: 300), () {
    AppSnackBar.warning('Session expired. Please login again.');
  });
}

// Endpoints  NOT trigger refresh token logic
const _authEndpoints = ['/auth/login', '/auth/register'];

bool _isAuthEndpoint(String path) {
  return _authEndpoints.any((ep) => path.contains(ep));
}

// Timers for slow-network detection, keyed by RequestOptions identity
final Map<int, Timer> _slowNetworkTimers = {};

void setupDioInterceptors() {
  apiClient.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // Start slow-network warning timer (fires after 4s)
        final key = options.hashCode;
        _slowNetworkTimers[key] = Timer(const Duration(seconds: 4), () {
          AppSnackBar.warning('Koneksi lambat, harap tunggu sebentar...');
        });

        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Cancel slow-network timer on success
        final key = response.requestOptions.hashCode;
        _slowNetworkTimers.remove(key)?.cancel();
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        // Cancel slow-network timer
        final key = e.requestOptions.hashCode;
        _slowNetworkTimers.remove(key)?.cancel();

        // Handle timeout errors immediately with a clear message
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          AppSnackBar.error(
            'Koneksi timeout. Periksa jaringan Anda dan coba lagi.',
          );
          return handler.next(e);
        }

        print(e.requestOptions.path);
        print(e.response?.statusCode);
        // Skip refresh logic for auth endpoints (login/register)
        if (e.response?.statusCode == 401 &&
            !_isAuthEndpoint(e.requestOptions.path)) {
          final prefs = await SharedPreferences.getInstance();
          final refreshToken = prefs.getString('refresh_token');

          if (refreshToken == null || refreshToken.isEmpty) {
            await _performLogout();
            return handler.reject(e);
          }

          try {
            final tempDio = Dio(BaseOptions(baseUrl: AppUrl.apiBaseUrl));
            final refreshResponse = await tempDio.post(
              '/auth/refreshToken',
              options: Options(
                headers: {'Authorization': 'Bearer $refreshToken'},
              ),
            );

            if (refreshResponse.statusCode == 200 &&
                refreshResponse.data != null &&
                refreshResponse.data['success'] == true) {
              final newAccessToken =
                  refreshResponse.data['data']['access_token'];
              final newRefreshToken =
                  refreshResponse.data['data']['refresh_token'] ?? refreshToken;

              await prefs.setString('access_token', newAccessToken);
              await prefs.setString('refresh_token', newRefreshToken);

              // Update the original request with the new access token
              final opts = e.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccessToken';

              // Repeat the original failed request
              final cloneReq = await apiClient.fetch(opts);
              return handler.resolve(cloneReq);
            } else {
              // Refresh token is invalid or expired
              await _performLogout();
              return handler.reject(e);
            }
          } catch (refreshError) {
            // Error occurred during refresh token API call
            await _performLogout();
            if (refreshError is DioException) {
              return handler.reject(refreshError);
            }
            return handler.reject(e);
          }
        }

        return handler.next(e);
      },
    ),
  );
}
