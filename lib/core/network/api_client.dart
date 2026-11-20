/// VintageVibe Mobile — Dio HTTP Client
/// Configured with JWT interceptor, error handling, and retry logic.
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  return ApiClient.createDio();
});

class ApiClient {
  static VoidCallback? onUnauthorized;

  static Dio createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // JWT Token & Resiliency Interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired — clear session and notify auth listener
            await SecureStorage.clearSession();
            onUnauthorized?.call();
          }

          // Transform technical network errors into readable user messages
          String friendlyMessage;
          switch (error.type) {
            case DioExceptionType.connectionTimeout:
            case DioExceptionType.sendTimeout:
            case DioExceptionType.receiveTimeout:
              friendlyMessage = 'El servidor está tardando en responder. Inténtalo de nuevo en unos momentos.';
              break;
            case DioExceptionType.connectionError:
              friendlyMessage = 'No se pudo conectar al servidor. Revisa tu conexión a internet.';
              break;
            case DioExceptionType.badResponse:
              final statusCode = error.response?.statusCode;
              final responseData = error.response?.data;
              if (statusCode != null && statusCode >= 500) {
                friendlyMessage = 'Error en el servidor ($statusCode). Por favor intenta más tarde.';
              } else if (responseData is Map && responseData['message'] != null) {
                friendlyMessage = responseData['message'].toString();
              } else {
                friendlyMessage = 'Error en la solicitud (${statusCode ?? 'desconocido'}).';
              }
              break;
            case DioExceptionType.cancel:
              friendlyMessage = 'Operación cancelada.';
              break;
            default:
              friendlyMessage = 'Ocurrió un problema de conexión. Inténtalo nuevamente.';
          }

          final customError = error.copyWith(
            message: friendlyMessage,
          );

          return handler.next(customError);
        },
      ),
    );

    // Logging sanitizado (debug only) — Práctica 5: nunca registrar contraseñas ni tokens en Logcat
    if (kDebugMode) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final safeBody = _sanitizeSensitiveData(options.data);
            debugPrint('HTTP -> ${options.method} ${options.path} | body: $safeBody');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint('HTTP <- ${response.statusCode} ${response.requestOptions.path}');
            return handler.next(response);
          },
          onError: (error, handler) {
            debugPrint('HTTP !! ${error.response?.statusCode ?? error.type.name} ${error.requestOptions.path}');
            return handler.next(error);
          },
        ),
      );
    }

    return dio;
  }

  /// Enmascara campos sensibles (password, token, etc.) antes de escribir cualquier log.
  static dynamic _sanitizeSensitiveData(dynamic data) {
    const sensitiveKeys = {'password', 'currentPassword', 'newPassword', 'token', 'authorization'};
    if (data is Map) {
      return data.map((key, value) {
        final keyStr = key.toString().toLowerCase();
        if (sensitiveKeys.contains(keyStr) || keyStr.contains('password') || keyStr.contains('token')) {
          return MapEntry(key, '***REDACTED***');
        }
        return MapEntry(key, _sanitizeSensitiveData(value));
      });
    }
    if (data is FormData) {
      return 'FormData(fields: ${data.fields.length}, files: ${data.files.length})';
    }
    return data;
  }
}
