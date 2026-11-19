/// VintageVibe Mobile — App Configuration
/// Centralized API URLs and app constants.

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  /// App identity
  static const String appName = 'VintageVibe';
  static const String appTagline = 'Discover Vintage Fashion';

  /// Active API URL
  static String get apiBaseUrl {
    final raw = dotenv.env['API_BASE_URL']?.trim();
    final baseUrl = (raw != null && raw.isNotEmpty)
        ? raw
        : 'https://vintagevibe-backend.onrender.com';
    return '$baseUrl/api/v1';
  }

  /// Secure storage keys
  static const String tokenKey = 'vv_token';
  static const String userKey = 'vv_user';

  /// Timeouts
  // Aumentamos a 60s porque los servidores gratuitos de Render (Cold Start) pueden tardar hasta 50s en despertar.
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// Pagination
  static const int defaultPageSize = 20;
}
