/// VintageVibe Mobile — Auth Providers (Riverpod)
/// State management for authentication flow.
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

// Auth state
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final AuthResponse? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    AuthResponse? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

// Auth notifier
class AuthNotifier extends Notifier<AuthState> {
  late AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    ApiClient.onUnauthorized = () {
      state = const AuthState(status: AuthStatus.unauthenticated);
    };
    _checkSession();
    return const AuthState(status: AuthStatus.initial);
  }

  Future<void> _checkSession() async {
    final user = await _repository.getStoredUser();
    if (user != null) {
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.login(
        LoginRequest(email: email, password: password),
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      String message = 'Error al iniciar sesión';
      if (e is Exception) {
        message = _parseError(e);
      }
      state = AuthState(status: AuthStatus.error, errorMessage: message);
    }
  }

  Future<void> register(String firstName, String lastName, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.register(
        RegisterRequest(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
        ),
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      String message = 'Error al registrarse';
      if (e is Exception) {
        message = _parseError(e);
      }
      state = AuthState(status: AuthStatus.error, errorMessage: message);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _parseError(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null) {
        final data = error.response!.data;
        if (data is Map && data.containsKey('message')) {
          return data['message'];
        }
      }
      switch (error.response?.statusCode) {
        case 401:
          return 'Credenciales incorrectas';
        case 403:
          return 'Acceso denegado';
        case 409:
          return 'Este email ya está registrado';
        case 500:
          return 'Error del servidor. Intenta más tarde';
        default:
          if (error.message != null && error.message!.isNotEmpty) {
            return error.message!;
          }
          return 'Error de conexión';
      }
    }
    return error.toString();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
