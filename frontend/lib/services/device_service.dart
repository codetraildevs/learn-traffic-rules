import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  String? _cachedDeviceId;

  /// Get unique device ID based on platform
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    try {
      String deviceId;

      if (kIsWeb) {
        // For web, use browser fingerprint
        deviceId = await _getWebDeviceId();
      } else if (Platform.isAndroid) {
        // For Android, use Android ID
        deviceId = await _getAndroidDeviceId();
      } else if (Platform.isIOS) {
        // For iOS, use identifierForVendor
        deviceId = await _getIOSDeviceId();
      } else {
        // Fallback for other platforms
        deviceId = await _getFallbackDeviceId();
      }

      _cachedDeviceId = deviceId;
      return deviceId;
    } catch (e) {
      // Fallback to timestamp-based ID
      _cachedDeviceId = 'device-${DateTime.now().millisecondsSinceEpoch}';
      return _cachedDeviceId!;
    }
  }

  Future<String> _getWebDeviceId() async {
    final webBrowserInfo = await _deviceInfo.webBrowserInfo;
    final packageInfo = await PackageInfo.fromPlatform();

    // Create a unique ID based on browser and app info
    final browserName = webBrowserInfo.browserName.name;
    final userAgent = webBrowserInfo.userAgent ?? '';
    final appVersion = packageInfo.version;

    // Generate a hash-like ID from browser characteristics
    final combined = '$browserName-$appVersion-${userAgent.length}';
    return 'web-${combined.hashCode.abs()}';
  }

  Future<String> _getAndroidDeviceId() async {
    final androidInfo = await _deviceInfo.androidInfo;
    return 'android-${androidInfo.id}';
  }

  Future<String> _getIOSDeviceId() async {
    final iosInfo = await _deviceInfo.iosInfo;
    return 'ios-${iosInfo.identifierForVendor ?? 'unknown'}';
  }

  Future<String> _getFallbackDeviceId() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${Platform.operatingSystem}-${packageInfo.packageName}-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get platform name for display
  String getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return Platform.operatingSystem;
  }

  /// Get device model for display
  Future<String> getDeviceModel() async {
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return '${webInfo.browserName.name} Browser';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return '${iosInfo.model} ${iosInfo.systemVersion}';
      }
      return 'Unknown Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }
}
