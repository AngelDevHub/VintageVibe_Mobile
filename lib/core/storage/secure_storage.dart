/// VintageVibe Mobile — Secure Storage Service
/// Manages JWT token and user session data using flutter_secure_storage.
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  // ==================== Token ====================
  static Future<void> saveToken(String token) async {
    await _storage.write(key: AppConfig.tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: AppConfig.tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: AppConfig.tokenKey);
  }

  // ==================== User Data ====================
  static Future<void> saveUser(Map<String, dynamic> user) async {
    await _storage.write(key: AppConfig.userKey, value: jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final data = await _storage.read(key: AppConfig.userKey);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<void> deleteUser() async {
    await _storage.delete(key: AppConfig.userKey);
  }

  // ==================== Session ====================
  static Future<void> clearSession() async {
    await Future.wait([
      deleteToken(),
      deleteUser(),
    ]);
  }

  static Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
