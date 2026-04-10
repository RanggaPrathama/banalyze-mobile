import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkChecker {
  NetworkChecker._();

  /// Returns true if the device has an active network interface.
  static Future<bool> hasConnection() async {
    final results = await Connectivity().checkConnectivity();
    return results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet,
    );
  }
}
