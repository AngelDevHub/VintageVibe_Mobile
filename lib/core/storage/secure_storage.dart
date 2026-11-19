/// VintageVibe Mobile — Secure Storage Service
/// Manages JWT token and user session data using flutter_secure_storage
/// with a safe in-memory fallback for Web/Safari contexts where WebCrypto may be unavailable.
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  // Fallback seguro en memoria si Safari/Web bloquea WebCrypto o almacenamiento
  static final Map<String, String> _memoryFallback = {};

  static Future<void> _write(String key, String value) async {
    _memoryFallback[key] = value;
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // Mantiene sesión activa en memoria si la plataforma restringe WebCrypto
    }
  }

  static Future<String?> _read(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value != null) return value;
    } catch (_) {
      // Fallback silencioso a memoria
    }
    return _memoryFallback[key];
  }

  static Future<void> _delete(String key) async {
    _memoryFallback.remove(key);
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  // ==================== Token ====================
  static Future<void> saveToken(String token) => _write(AppConfig.tokenKey, token);

  static Future<String?> getToken() => _read(AppConfig.tokenKey);

  static Future<void> deleteToken() => _delete(AppConfig.tokenKey);

  // ==================== User Data ====================
  static Future<void> saveUser(Map<String, dynamic> user) =>
      _write(AppConfig.userKey, jsonEncode(user));

  static Future<Map<String, dynamic>?> getUser() async {
    final data = await _read(AppConfig.userKey);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<void> deleteUser() => _delete(AppConfig.userKey);

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

  // ==================== Generic Preferences / Favorites ====================
  static Future<void> writeValue(String key, String value) => _write(key, value);

  static Future<String?> readValue(String key) => _read(key);

  static Future<void> deleteValue(String key) => _delete(key);
}
