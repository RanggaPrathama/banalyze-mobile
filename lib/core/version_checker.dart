import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:banalyze/shared/widgets/update_dialog.dart';

// file `version.json`:
///    {
///      "latest_version": "1.1.0",
///      "min_version":    "1.0.0",
///      "store_url":      "https://play.google.com/store/apps/details?id=YOUR_PACKAGE_ID",
///      "force_update":   false
///    }
///
///   [_remoteVersionUrl] dengan URL file tersebut.
///    'https://raw.githubusercontent.com/USERNAME/REPO/main/version.json'
///
/// ─── Field JSON ──────────────────────────────────────────────────────────────
/// • latest_version : versi terbaru yang tersedia
/// • min_version    : versi minimum yang didukung (opsional)
///                    jika app di bawah ini → force update (dialog tidak bisa ditutup)
/// • store_url      : link Play Store / App Store
/// • force_update   : paksa update tanpa bisa ditutup (override min_version)
/// ─────────────────────────────────────────────────────────────────────────────
class VersionChecker {
  VersionChecker._();

  static const String _remoteVersionUrl = '';

  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  static Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

 
  static int _compareVersions(String v1, String v2) {
    List<int> parse(String v) =>
        v.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final p1 = parse(v1);
    final p2 = parse(v2);
    final len = p1.length > p2.length ? p1.length : p2.length;

    for (int i = 0; i < len; i++) {
      final a = i < p1.length ? p1[i] : 0;
      final b = i < p2.length ? p2[i] : 0;
      if (a < b) return -1;
      if (a > b) return 1;
    }
    return 0;
  }

  /// Mengambil info versi dari URL remote, membandingkan dengan versi saat ini,
  /// dan menampilkan [UpdateDialog] jika ada versi baru.
  ///
  /// Tidak melakukan apa-apa jika [_remoteVersionUrl] kosong atau terjadi error.
  static Future<void> checkAndShowUpdateDialog(BuildContext context) async {
    if (_remoteVersionUrl.isEmpty) return;

    try {
      final response = await _dio.get<Map<String, dynamic>>(_remoteVersionUrl);
      final data = response.data;
      if (data == null) return;

      final latestVersion = (data['latest_version'] as String? ?? '').trim();
      final minVersion = (data['min_version'] as String? ?? '').trim();
      final storeUrl = (data['store_url'] as String? ?? '').trim();
      final forceUpdate = data['force_update'] as bool? ?? false;

      if (latestVersion.isEmpty) return;

      final currentVersion = await getCurrentVersion();

      final hasUpdate = _compareVersions(currentVersion, latestVersion) < 0;
      final mustUpdate =
          minVersion.isNotEmpty &&
          _compareVersions(currentVersion, minVersion) < 0;

      if (!hasUpdate && !mustUpdate) return;
      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: !(forceUpdate || mustUpdate),
        builder: (_) => UpdateDialog(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          storeUrl: storeUrl,
          forceUpdate: forceUpdate || mustUpdate,
        ),
      );
    } catch (_) {
    }
  }
}
