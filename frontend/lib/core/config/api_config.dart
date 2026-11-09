import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

abstract final class ApiConfig {
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          return 'http://10.0.2.2:5000/api';
        }
      } catch (_) {}
    }
    return 'http://localhost:5000/api';
  }
}
