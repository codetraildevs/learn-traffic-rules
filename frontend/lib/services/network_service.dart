import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();

  /// Check if device has internet connectivity
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('🌐 NETWORK: No connectivity');
        return false;
      }

      // For mobile networks, try to reach a reliable server
      if (connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi) {
        try {
          final result = await InternetAddress.lookup('google.com');
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            debugPrint('🌐 NETWORK: Internet connection confirmed');
            return true;
          }
        } catch (e) {
          debugPrint('🌐 NETWORK: Internet check failed: $e');
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('🌐 NETWORK: Connectivity check failed: $e');
      return false;
    }
  }

  /// Get current connectivity status
  Future<ConnectivityResult> getConnectivityStatus() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      debugPrint('🌐 NETWORK: Failed to get connectivity status: $e');
      return ConnectivityResult.none;
    }
  }

  /// Stream of connectivity changes
  Stream<ConnectivityResult> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  /// Check if connected to WiFi
  Future<bool> isConnectedToWifi() async {
    final result = await getConnectivityStatus();
    return result == ConnectivityResult.wifi;
  }

  /// Check if connected to mobile data
  Future<bool> isConnectedToMobile() async {
    final result = await getConnectivityStatus();
    return result == ConnectivityResult.mobile;
  }

  /// Get user-friendly connectivity status
  Future<String> getConnectivityStatusText() async {
    final result = await getConnectivityStatus();
    switch (result) {
      case ConnectivityResult.wifi:
        return 'Connected to WiFi';
      case ConnectivityResult.mobile:
        return 'Connected to Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Connected to Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Connected via Bluetooth';
      case ConnectivityResult.vpn:
        return 'Connected via VPN';
      case ConnectivityResult.other:
        return 'Connected to Other Network';
      case ConnectivityResult.none:
        return 'No Internet Connection';
    }
  }

  /// Wait for internet connection with timeout
  Future<bool> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      if (await hasInternetConnection()) {
        return true;
      }

      // Wait 2 seconds before checking again
      await Future.delayed(const Duration(seconds: 2));
    }

    return false;
  }
}
