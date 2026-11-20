/// VintageVibe Mobile — Auth Repository
/// Handles all authentication API calls and session management.
import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  /// Login with email and password → returns AuthResponse with JWT
  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: request.toJson(),
    );
    final authResponse = AuthResponse.fromJson(response.data);
    await _saveSession(authResponse);
    return authResponse;
  }

  /// Register a new account → returns AuthResponse with JWT
  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await _dio.post(
      ApiEndpoints.register,
      data: request.toJson(),
    );
    final authResponse = AuthResponse.fromJson(response.data);
    await _saveSession(authResponse);
    return authResponse;
  }

  /// Logout → clears local session immediately and optionally notifies backend
  Future<void> logout() async {
    // 1. Limpiar sesión local INMEDIATAMENTE para que la app no quede bloqueada
    await SecureStorage.clearSession();

    // 2. Notificar al backend de forma asíncrona con timeout corto (3s)
    try {
      await _dio.post(
        ApiEndpoints.logout,
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
    } catch (_) {
      // Si el servidor está dormido o no hay red, la sesión local ya fue eliminada con éxito
    }
  }

  /// Check if user has a valid session
  Future<bool> hasSession() => SecureStorage.hasSession();

  /// Get the stored user data
  Future<AuthResponse?> getStoredUser() async {
    final userData = await SecureStorage.getUser();
    if (userData != null) {
      return AuthResponse.fromJson(userData);
    }
    return null;
  }

  /// Get the stored token
  Future<String?> getToken() => SecureStorage.getToken();

  Future<void> _saveSession(AuthResponse response) async {
    await Future.wait([
      SecureStorage.saveToken(response.token),
      SecureStorage.saveUser(response.toJson()),
    ]);
  }
}
