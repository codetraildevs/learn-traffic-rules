import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  String? _cachedDeviceId;
  String? _cachedDeviceFingerprint;

  /// Get unique device ID with high security binding
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    try {
      // Try to get stored device ID first
      final prefs = await SharedPreferences.getInstance();
      final storedId = prefs.getString('secure_device_id');

      if (storedId != null && storedId.isNotEmpty) {
        // Verify the stored ID is still valid for this device
        final currentFingerprint = await _generateDeviceFingerprint();
        final storedFingerprint = prefs.getString('device_fingerprint');

        if (storedFingerprint == currentFingerprint) {
          _cachedDeviceId = storedId;
          return storedId;
        } else {
          // Device fingerprint changed, generate new ID
          await prefs.remove('secure_device_id');
          await prefs.remove('device_fingerprint');
        }
      }

      // Generate new secure device ID
      String deviceId;
      if (kIsWeb) {
        deviceId = await _getWebDeviceId();
      } else if (Platform.isAndroid) {
        deviceId = await _getAndroidDeviceId();
      } else if (Platform.isIOS) {
        deviceId = await _getIOSDeviceId();
      } else {
        deviceId = await _getFallbackDeviceId();
      }

      // Store the device ID and fingerprint for future verification
      final fingerprint = await _generateDeviceFingerprint();
      await prefs.setString('secure_device_id', deviceId);
      await prefs.setString('device_fingerprint', fingerprint);

      // Debug logging for device ID generation
      if (kDebugMode) {
        debugPrint('🔧 DEVICE ID GENERATED:');
        debugPrint('   Device ID: $deviceId');
        debugPrint('   Fingerprint: ${fingerprint.substring(0, 8)}...');
        // debugPrint('   Platform: $platformName');
      }

      _cachedDeviceId = deviceId;
      return deviceId;
    } catch (e) {
      // Fallback to timestamp-based ID (less secure but functional)
      _cachedDeviceId = 'device-${DateTime.now().millisecondsSinceEpoch}';
      return _cachedDeviceId!;
    }
  }

  /// Generate a unique device fingerprint for security verification
  Future<String> _generateDeviceFingerprint() async {
    if (_cachedDeviceFingerprint != null) return _cachedDeviceFingerprint!;

    try {
      String fingerprintData = '';

      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        final packageInfo = await PackageInfo.fromPlatform();
        fingerprintData =
            '${webInfo.browserName.name}-${webInfo.platform ?? 'unknown'}-${webInfo.vendor ?? 'unknown'}-${packageInfo.packageName}';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        final packageInfo = await PackageInfo.fromPlatform();
        // Create a more comprehensive fingerprint for better security
        fingerprintData = [
          androidInfo.brand,
          androidInfo.model,
          androidInfo.id,
          androidInfo.fingerprint,
          androidInfo.hardware,
          androidInfo.product,
          androidInfo.device,
          androidInfo.board,
          androidInfo.manufacturer,
          packageInfo.packageName,
          packageInfo.version,
        ].join('-');
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        final packageInfo = await PackageInfo.fromPlatform();
        fingerprintData =
            '${iosInfo.name}-${iosInfo.model}-${iosInfo.systemName}-${packageInfo.packageName}';
      } else {
        final packageInfo = await PackageInfo.fromPlatform();
        fingerprintData =
            '${Platform.operatingSystem}-${packageInfo.packageName}-${packageInfo.version}';
      }

      // Create a hash of the fingerprint data
      final bytes = utf8.encode(fingerprintData);
      final digest = sha256.convert(bytes);
      _cachedDeviceFingerprint = digest.toString();
      return _cachedDeviceFingerprint!;
    } catch (e) {
      // Fallback fingerprint
      _cachedDeviceFingerprint =
          'fallback-${DateTime.now().millisecondsSinceEpoch}';
      return _cachedDeviceFingerprint!;
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
    final combined = '$browserName-$appVersion-${userAgent.hashCode}';
    return 'web-${combined.hashCode}';
  }

  Future<String> _getAndroidDeviceId() async {
    final androidInfo = await _deviceInfo.androidInfo;
    final packageInfo = await PackageInfo.fromPlatform();

    // Create a consistent device ID using device characteristics only
    // This ensures the same device always gets the same ID
    final deviceCharacteristics = [
      androidInfo.brand, // Device brand (e.g., TECNO)
      androidInfo.model, // Device model (e.g., TECNO BF7)
      androidInfo.id, // Android ID (same for same device)
      androidInfo.fingerprint, // Build fingerprint
      androidInfo.hardware, // Hardware info
      androidInfo.product, // Product name
      packageInfo.packageName, // App package name
      // Removed timestamp to ensure consistency
    ];

    // Create a hash from all characteristics
    final combined = deviceCharacteristics.join('-');
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);

    // Return a shorter, more readable ID
    return 'android-${digest.toString().substring(0, 16)}';
  }

  Future<String> _getIOSDeviceId() async {
    final iosInfo = await _deviceInfo.iosInfo;
    // Use identifierForVendor for high security and consistency
    final identifier =
        iosInfo.identifierForVendor ?? iosInfo.name ?? 'unknown-ios-device';
    return 'ios-${identifier.hashCode}';
  }

  Future<String> _getFallbackDeviceId() async {
    final packageInfo = await PackageInfo.fromPlatform();
    // Use consistent characteristics without timestamp
    final combined =
        '${Platform.operatingSystem}-${packageInfo.packageName}-${packageInfo.version}';
    return 'fallback-${combined.hashCode}';
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
        return '${iosInfo.name} ${iosInfo.model}';
      }
      return 'Unknown Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  /// Verify device binding for security
  Future<bool> verifyDeviceBinding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedFingerprint = prefs.getString('device_fingerprint');
      final currentFingerprint = await _generateDeviceFingerprint();

      return storedFingerprint == currentFingerprint;
    } catch (e) {
      return false;
    }
  }

  /// Clear device binding (for logout or security reset)
  Future<void> clearDeviceBinding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('secure_device_id');
    await prefs.remove('device_fingerprint');
    _cachedDeviceId = null;
    _cachedDeviceFingerprint = null;
  }

  /// Generate a new device ID (useful for testing or device changes)
  Future<String> generateNewDeviceId() async {
    // Clear cached data
    _cachedDeviceId = null;
    _cachedDeviceFingerprint = null;

    // Clear stored data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('secure_device_id');
    await prefs.remove('device_fingerprint');

    // Generate new ID
    return await getDeviceId();
  }

  /// Check if this is an admin device (for testing)
  bool isAdminDevice() {
    return _cachedDeviceId == 'admin-device-bypass';
  }

  /// Get enhanced device fingerprint for security
  Future<String> getEnhancedFingerprint() async {
    if (_cachedDeviceFingerprint != null) return _cachedDeviceFingerprint!;

    try {
      final fingerprint = await _generateEnhancedFingerprint();
      _cachedDeviceFingerprint = fingerprint;
      return fingerprint;
    } catch (e) {
      debugPrint('Error generating enhanced fingerprint: $e');
      return await _generateDeviceFingerprint();
    }
  }

  /// Generate enhanced device fingerprint with more security features
  Future<String> _generateEnhancedFingerprint() async {
    final components = <String>[];

    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        components.addAll([
          webInfo.browserName.name,
          webInfo.platform ?? 'unknown',
          webInfo.vendor ?? 'unknown',
          webInfo.userAgent ?? 'unknown',
        ]);
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        components.addAll([
          androidInfo.brand,
          androidInfo.model,
          androidInfo.device,
          androidInfo.product,
          androidInfo.hardware,
          androidInfo.fingerprint,
          androidInfo.id,
        ]);
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        components.addAll([
          iosInfo.name,
          iosInfo.model,
          iosInfo.systemName,
          iosInfo.systemVersion,
          iosInfo.localizedModel,
          iosInfo.identifierForVendor ?? 'unknown',
        ]);
      }

      // Add package info for additional security
      final packageInfo = await PackageInfo.fromPlatform();
      components.addAll([
        packageInfo.packageName,
        packageInfo.version,
        packageInfo.buildNumber,
      ]);

      // Add timestamp for uniqueness
      components.add(DateTime.now().millisecondsSinceEpoch.toString());

      // Create hash
      final combined = components.join('|');
      final bytes = utf8.encode(combined);
      final digest = sha256.convert(bytes);

      return digest.toString();
    } catch (e) {
      debugPrint('Error in enhanced fingerprint generation: $e');
      return await _generateDeviceFingerprint();
    }
  }
}
