import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Utility for checking real internet connectivity.
///
/// [hasConnection] uses [connectivity_plus] as a fast first gate, then falls
/// back to an actual TCP socket check so we never false-positive on WiFi
/// interfaces that have no upstream (e.g. hotspot with no data).
class NetworkChecker {
  NetworkChecker._();

  /// Returns true if the device currently has a working internet connection.
  static Future<bool> hasConnection() async {
    // Step 1: fast check — if no interface at all, bail immediately
    final results = await Connectivity().checkConnectivity();
    final hasInterface = results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet,
    );
    if (!hasInterface) return false;

    // Step 2: actual reachability — try a TCP connection to a reliable host
    try {
      final socket = await Socket.connect(
        '8.8.8.8',
        53,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}
