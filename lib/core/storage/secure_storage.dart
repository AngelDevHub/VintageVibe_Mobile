/// VintageVibe Mobile — Secure Storage Service
/// Manages JWT token and user session data using flutter_secure_storage
/// with persistent SharedPreferences / LocalStorage fallback for iOS Safari and PWA environments.
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  static final Map<String, String> _memoryFallback = {};
  static SharedPreferences? _prefsInstance;

  static Future<SharedPreferences> _getPrefs() async {
    _prefsInstance ??= await SharedPreferences.getInstance();
    return _prefsInstance!;
  }

  static Future<void> _write(String key, String value) async {
    _memoryFallback[key] = value;

    // 1. Persistir permanentemente en SharedPreferences (funciona en Safari PWA y no se borra al cerrar)
    try {
      final prefs = await _getPrefs();
      await prefs.setString(key, value);
    } catch (_) {}

    // 2. Persistir en SecureStorage nativo
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // Si Safari restringe WebCrypto, SharedPreferences ya aseguró la persistencia en disco
    }
  }

  static Future<String?> _read(String key) async {
    // 1. Memoria rápida
    if (_memoryFallback.containsKey(key)) {
      return _memoryFallback[key];
    }

    // 2. SecureStorage nativo
    try {
      final value = await _storage.read(key: key);
      if (value != null && value.isNotEmpty) {
        _memoryFallback[key] = value;
        return value;
      }
    } catch (_) {}

    // 3. Fallback persistente de SharedPreferences (recupera sesión al reabrir la PWA en iOS)
    try {
      final prefs = await _getPrefs();
      final value = prefs.getString(key);
      if (value != null && value.isNotEmpty) {
        _memoryFallback[key] = value;
        return value;
      }
    } catch (_) {}

    return null;
  }

  static Future<void> _delete(String key) async {
    _memoryFallback.remove(key);
    try {
      final prefs = await _getPrefs();
      await prefs.remove(key);
    } catch (_) {}
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
