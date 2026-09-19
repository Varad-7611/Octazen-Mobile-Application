import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  /// Default Wi-Fi IP address of the local developer machine for wireless debugging on physical mobile devices.
  static const String defaultNetworkHost = String.fromEnvironment(
    'BACKEND_HOST',
    defaultValue: '192.168.1.103',
  );

  /// Returns the full backend API base URL (e.g. http://192.168.1.8:5000/api).
  static String get baseUrl {
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredUrl.isNotEmpty) return configuredUrl;

    if (kIsWeb) {
      return 'http://127.0.0.1:5000/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      // For wireless debugging on physical mobile devices:
      return 'http://$defaultNetworkHost:5000/api';
    }

    return 'http://127.0.0.1:5000/api';
  }

  /// Helper for courses API endpoint
  static String get coursesUrl => '$baseUrl/courses';
}
