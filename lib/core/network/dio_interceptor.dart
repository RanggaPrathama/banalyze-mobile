import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:banalyze/app.dart';
import 'package:banalyze/router/app_router.dart';
import 'package:banalyze/shared/widgets/app_snackbar.dart';
import 'package:banalyze/core/constants/app_url.dart';
import 'package:banalyze/core/network/network_checker.dart';

/// Endpoints that must NOT trigger the refresh-token logic.
const _authEndpoints = ['/auth/login', '/auth/register'];

bool _isAuthEndpoint(String path) =>
    _authEndpoints.any((ep) => path.contains(ep));

/// Timers keyed by [RequestOptions.hashCode]. Cancelled on response/error.
final Map<int, Timer> _slowNetworkTimers = {};

// ── Logout helper
Future<void> _performLogout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('access_token');
  await prefs.remove('refresh_token');

  FocusManager.instance.primaryFocus?.unfocus();
  navigatorKey.currentState?.pushNamedAndRemoveUntil(
    AppRouter.login,
    (route) => false,
  );

  Future.delayed(const Duration(milliseconds: 300), () {
    AppSnackBar.warning('Session expired. Please login again.');
  });
}

// ── Main interceptor setup
/// Attaches all interceptors to [client].
/// Call once at app startup (from [setupDioInterceptors]).
void attachDioInterceptors(Dio client) {
  client.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: _onRequest,
      onResponse: _onResponse,
      onError: (e, handler) => _onError(client, e, handler),
    ),
  );
}

Future<void> _onRequest(
  RequestOptions options,
  RequestInterceptorHandler handler,
) async {
  final online = await NetworkChecker.hasConnection();
  if (!online) {
    AppSnackBar.error(
      'Tidak ada koneksi internet. Periksa WiFi atau data seluler Anda.',
    );
    return handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'No internet connection',
      ),
    );
  }

  // ── Auth token ─────────────────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');
  if (token != null && token.isNotEmpty) {
    options.headers['Authorization'] = 'Bearer $token';
  }

  // ── Slow-network warning timer (fires after 10 s) ───────────────────────
  final key = options.hashCode;
  _slowNetworkTimers[key] = Timer(const Duration(seconds: 10), () {
    AppSnackBar.warning('Koneksi lambat, harap tunggu sebentar...');
  });

  return handler.next(options);
}

// ── Response ──────────────────────────────────────────────────────────────────

void _onResponse(Response response, ResponseInterceptorHandler handler) {
  _slowNetworkTimers.remove(response.requestOptions.hashCode)?.cancel();
  handler.next(response);
}

// ── Error ─────────────────────────────────────────────────────────────────────

Future<void> _onError(
  Dio client,
  DioException e,
  ErrorInterceptorHandler handler,
) async {
  _slowNetworkTimers.remove(e.requestOptions.hashCode)?.cancel();

  // ── Timeout ───────────────────────────────────────────────────────────
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    // Secondary connectivity check to give a more specific message
    final online = await NetworkChecker.hasConnection();
    if (!online) {
      AppSnackBar.error(
        'Tidak ada koneksi internet. Periksa WiFi atau data seluler Anda.',
      );
    } else {
      AppSnackBar.error(
        'Server tidak merespons. Coba lagi dalam beberapa saat.',
      );
    }
    return handler.next(e);
  }

  // ── Connection error (no route to host, etc.) ─────────────────────────
  if (e.type == DioExceptionType.connectionError) {
    // Only show snackbar if we didn't already reject in onRequest
    if (e.message != 'No internet connection') {
      AppSnackBar.error(
        'Tidak ada koneksi internet. Periksa WiFi atau data seluler Anda.',
      );
    }
    return handler.next(e);
  }

  // ── 401 – token refresh flow ──────────────────────────────────────────
  if (e.response?.statusCode == 401 &&
      !_isAuthEndpoint(e.requestOptions.path)) {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null || refreshToken.isEmpty) {
      await _performLogout();
      return handler.reject(e);
    }

    // Check network before attempting refresh — avoid false logouts
    final onlineBeforeRefresh = await NetworkChecker.hasConnection();
    if (!onlineBeforeRefresh) {
      AppSnackBar.error(
        'Tidak ada koneksi internet. Periksa WiFi atau data seluler Anda.',
      );
      return handler.next(e);
    }

    try {
      final tempDio = Dio(
        BaseOptions(
          baseUrl: AppUrl.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final refreshResponse = await tempDio.post(
        '/auth/refreshToken',
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );

      if (refreshResponse.statusCode == 200 &&
          refreshResponse.data != null &&
          refreshResponse.data['success'] == true) {
        final newAccessToken = refreshResponse.data['data']['access_token'];
        final newRefreshToken =
            refreshResponse.data['data']['refresh_token'] ?? refreshToken;

        await prefs.setString('access_token', newAccessToken);
        await prefs.setString('refresh_token', newRefreshToken);

        final opts = e.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccessToken';

        final cloneReq = await client.fetch(opts);
        return handler.resolve(cloneReq);
      } else {
        await _performLogout();
        return handler.reject(e);
      }
    } catch (refreshError) {
      // If the refresh call itself timed out or lost connectivity, do NOT
      // log the user out — the session may still be valid once connectivity
      // is restored. Show an appropriate message and keep the error going.
      if (refreshError is DioException) {
        final isNetworkFailure =
            refreshError.type == DioExceptionType.connectionTimeout ||
            refreshError.type == DioExceptionType.receiveTimeout ||
            refreshError.type == DioExceptionType.sendTimeout ||
            refreshError.type == DioExceptionType.connectionError;

        if (isNetworkFailure) {
          final stillOnline = await NetworkChecker.hasConnection();
          if (!stillOnline) {
            AppSnackBar.error(
              'Tidak ada koneksi internet. Periksa WiFi atau data seluler Anda.',
            );
          } else {
            AppSnackBar.error(
              'Server tidak merespons. Coba lagi dalam beberapa saat.',
            );
          }
          return handler.next(e);
        }

        await _performLogout();
        return handler.reject(refreshError);
      }
      await _performLogout();
      return handler.reject(e);
    }
  }

  handler.next(e);
}
