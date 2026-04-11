import 'package:flutter/foundation.dart';
import 'package:banalyze/core/api_client.dart';
import 'package:banalyze/shared/models/user_model.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserModel? _user;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  UserModel? get user => _user;

  Future<bool> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    // No token locally — skip network call
    if (token == null || token.isEmpty) {
      _isLoggedIn = false;
      notifyListeners();
      return false;
    }

    // Restore cached user while we validate in the background
    final userJson = prefs.getString('user');
    if (userJson != null) {
      _user = UserModel.fromJson(userJson);
    }

    try {
      final response = await apiClient.get('/auth/me');
      debugPrint('Auth check response: ${response.data}');
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        _user = UserModel.fromMap(data as Map<String, dynamic>);
        await prefs.setString('user', _user!.toJson());
        _isLoggedIn = true;
        notifyListeners();
        return true;
      } else {
        // Unexpected non-success response
        await logout();
        return false;
      }
    } on DioException catch (e) {
      // 401 is handled by the interceptor (refresh + auto logout).
      // Any other network error (timeout, no connection) — keep user
      // logged in with cached data so they aren't unnecessarily kicked out.
      if (e.response?.statusCode == 401) {
        // Interceptor will handle logout — just mark not logged in here
        _isLoggedIn = false;
        notifyListeners();
        return false;
      }
      // Network error (no internet, timeout) — trust local token
      _isLoggedIn = true;
      notifyListeners();
      return true;
    } catch (_) {
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user');

    _isLoggedIn = false;
    _user = null;
    notifyListeners();
  }

  /// Update user data in-place and persist to SharedPreferences.
  Future<void> updateUser(UserModel updated) async {
    _user = updated;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', updated.toJson());
  }

  void setError(String error) {
    _error = error;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (email.isEmpty || password.isEmpty) {
      _error = 'Please fill in all fields';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final response = await apiClient.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];

        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];

        final prefs = await SharedPreferences.getInstance();
        if (accessToken != null) {
          await prefs.setString('access_token', accessToken);
        }
        if (refreshToken != null) {
          await prefs.setString('refresh_token', refreshToken);
        }

        var user = {
          'id': data['id'],
          'nama_user': data['nama_user'],
          'email': data['email'],
        };

        _user = UserModel.fromMap(user);
        await prefs.setString('user', _user!.toJson());

        _isLoggedIn = true;
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to login';
        return false;
      }
    } on DioException catch (e) {
      debugPrint('DioException response data: ${e.response?.data}');
      if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        _error = 'Server tidak merespons. Coba lagi dalam beberapa saat.';
      } else if (e.type == DioExceptionType.connectionError) {
        _error =
            'Tidak ada koneksi internet. Periksa WiFi atau data seluler Anda.';
      } else if (e.response != null && e.response?.data is Map) {
        _error = e.response?.data['message'] ?? 'Email atau password salah';
      } else {
        _error = 'Terjadi kesalahan server. Coba lagi.';
      }
      return false;
    } catch (e) {
      _error = 'Terjadi kesalahan sistem: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _error = 'Please fill in all fields';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (password != confirmPassword) {
      _error = 'Passwords do not match';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (password.length < 6) {
      _error = 'Password must be at least 6 characters';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final response = await apiClient.post(
        '/auth/register',
        data: {'nama_user': name, 'email': email, 'password': password},
      );

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];

        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];

        // Simpan ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        if (accessToken != null) {
          await prefs.setString('access_token', accessToken);
        }
        if (refreshToken != null) {
          await prefs.setString('refresh_token', refreshToken);
        }
        _user = UserModel.fromMap({
          'id': data['id'],
          'nama_user': data['nama_user'],
          'email': data['email'],
        });
        await prefs.setString('user', _user!.toJson());

        _isLoggedIn = true;
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to register';
        return false;
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        _error = 'Server tidak merespons. Coba lagi dalam beberapa saat.';
      } else if (e.type == DioExceptionType.connectionError) {
        _error =
            'Tidak ada koneksi internet. Periksa WiFi atau data seluler Anda.';
      } else if (e.response != null && e.response?.data is Map) {
        _error = e.response?.data['message'] ?? 'Gagal mendaftar';
      } else {
        _error = 'Terjadi kesalahan server. Coba lagi.';
      }
      return false;
    } catch (e) {
      _error = 'Terjadi kesalahan sistem: ${e.toString()}';
      return false;
    } finally {
      // Selalu update UI selesai loading, terlepas berhasil atau error.
      _isLoading = false;
      notifyListeners();
    }
  }
}
