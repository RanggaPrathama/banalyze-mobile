import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:banalyze/core/api_client.dart';
import 'package:banalyze/shared/widgets/app_snackbar.dart';
import 'package:banalyze/features/auth/providers/auth_provider.dart';
import 'package:banalyze/shared/models/user_model.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider()
    : fullNameController = TextEditingController(text: ''),
      phoneController = TextEditingController(text: '');

  final TextEditingController fullNameController;
  final TextEditingController phoneController;

  bool _ripenessAlerts = true;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _avatarUrl;

  bool get ripenessAlerts => _ripenessAlerts;
  bool get isSaving => _isSaving;
  bool get isUploadingAvatar => _isUploadingAvatar;
  String? get avatarUrl => _avatarUrl;

  void setRipenessAlerts(bool value) {
    if (_ripenessAlerts == value) return;
    _ripenessAlerts = value;
    notifyListeners();
  }

  void loadFromUser({String? name, String? phone, String? avatar}) {
    fullNameController.text = name ?? '';
    phoneController.text = phone ?? '';
    _avatarUrl = avatar;
    print(_avatarUrl);
    notifyListeners();
  }

  /// PUT /api/user/profile — { nama_user, no_telephone }
  Future<bool> saveProfile({AuthProvider? authProvider}) async {
    _isSaving = true;
    notifyListeners();

    try {
      final response = await apiClient.put(
        '/user/profile',
        data: {
          'nama_user': fullNameController.text.trim(),
          'no_telephone': phoneController.text.trim(),
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Update AuthProvider user in-place so UI reflects new data immediately
        if (authProvider != null) {
          final data = response.data['data'];
          final updated = data != null
              ? UserModel.fromMap(data as Map<String, dynamic>)
              : authProvider.user?.copyWith(
                  name: fullNameController.text.trim(),
                  phone: phoneController.text.trim(),
                );
          if (updated != null) await authProvider.updateUser(updated);
        }
        AppSnackBar.success('Profile updated successfully');
        _isSaving = false;
        notifyListeners();
        return true;
      } else {
        final msg = response.data['message'] ?? 'Failed to update profile';
        AppSnackBar.error(msg);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Network error. Try again.';
      AppSnackBar.error(msg);
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  /// PUT /api/user/profile/avatar — multipart/form-data { file }
  Future<void> uploadAvatar(
    File imageFile, {
    AuthProvider? authProvider,
  }) async {
    _isUploadingAvatar = true;
    notifyListeners();

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'avatar.jpg',
        ),
      });

      final response = await apiClient.put(
        '/user/profile/avatar',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        _avatarUrl = response.data['data']?['avatar_url'];
        if (authProvider != null && _avatarUrl != null) {
          final updated = authProvider.user?.copyWith(avatarUrl: _avatarUrl);
          if (updated != null) await authProvider.updateUser(updated);
        }
        AppSnackBar.success('Avatar updated');
      } else {
        final msg = response.data['message'] ?? 'Failed to upload avatar';
        AppSnackBar.error(msg);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Network error. Try again.';
      AppSnackBar.error(msg);
    }

    _isUploadingAvatar = false;
    notifyListeners();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
