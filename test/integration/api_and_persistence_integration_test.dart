import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/api_endpoints.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/features/auth/data/models/auth_models.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';

/// Adaptador HTTP en memoria para pruebas de integración reales con Dio
/// sin depender de la red externa en el pipeline CI/CD.
typedef MockRequestHandler = Future<ResponseBody> Function(RequestOptions options);

class MockHttpClientAdapter implements HttpClientAdapter {
  final MockRequestHandler onFetch;

  MockHttpClientAdapter(this.onFetch);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Map<String, dynamic> body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fase 3 - Pruebas de Integración: API, Riverpod y Persistencia (VintageVibe)', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    // Integración 1 (AUT-04): Comunicación App -> Servicio REST -> Riverpod State (HTTP 200 OK)
    test('AUT-04: CartNotifier + CartRepository envían POST /cart/items y reciben HTTP 200 OK', () async {
      final capturedRequests = <RequestOptions>[];

      final dio = Dio(BaseOptions(baseUrl: 'https://vintagevibe-backend.onrender.com/api/v1'));
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        capturedRequests.add(options);

        if (options.method == 'GET' && options.path == ApiEndpoints.cart) {
          return jsonResponse({'id': 1, 'userId': 3, 'items': [], 'total': 0.0}, 200);
        }

        if (options.method == 'POST' && options.path == ApiEndpoints.cartItems) {
          expect(options.data, equals({'variantId': 101, 'quantity': 1}));
          return jsonResponse({
            'id': 1,
            'userId': 3,
            'total': 450.0,
            'items': [
              {
                'id': 55,
                'variantId': 101,
                'productName': 'Sudadera Vintage 90s',
                'variantSku': 'SUD-90-L',
                'size': 'L',
                'color': 'Beige',
                'price': 450.0,
                'quantity': 1,
                'stock': 1,
              },
            ],
          }, 200);
        }

        return jsonResponse({'message': 'Not Found'}, 404);
      });

      final container = ProviderContainer(
        overrides: [dioProvider.overrideWithValue(dio)],
      );
      addTearDown(container.dispose);

      // 1. Cargar carrito inicial vacío
      final initialCart = await container.read(cartProvider.future);
      expect(initialCart.items, isEmpty);

      // 2. Agregar producto y verificar respuesta 200 OK y actualización reactiva
      final error = await container.read(cartProvider.notifier).addProduct(101, 1);
      expect(error, isNull);

      final updatedCart = container.read(cartProvider).asData?.value;
      expect(updatedCart, isNotNull);
      expect(updatedCart!.items.length, equals(1));
      expect(updatedCart.items.first.productName, equals('Sudadera Vintage 90s'));
      expect(updatedCart.total, equals(450.0));
      expect(capturedRequests.any((r) => r.method == 'POST' && r.path == ApiEndpoints.cartItems), isTrue);
    });

    // Integración 2 (AUT-05): Manejo de HTTP 400 Bad Request por stock insuficiente sin colapsar estado
    test('AUT-05: Ante HTTP 400 (Stock insuficiente), CartNotifier conserva estado previo y devuelve mensaje', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://vintagevibe-backend.onrender.com/api/v1'));
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        if (options.method == 'GET' && options.path == ApiEndpoints.cart) {
          return jsonResponse({
            'id': 1,
            'userId': 3,
            'total': 450.0,
            'items': [
              {
                'id': 55,
                'variantId': 101,
                'productName': 'Sudadera Vintage 90s',
                'variantSku': 'SUD-90-L',
                'size': 'L',
                'color': 'Beige',
                'price': 450.0,
                'quantity': 1,
                'stock': 1,
              },
            ],
          }, 200);
        }

        if (options.method == 'POST' && options.path == ApiEndpoints.cartItems) {
          return jsonResponse(
            {'message': 'Stock insuficiente para Sudadera Vintage 90s. Solo hay 1 unidad(es) disponible(s).'},
            400,
          );
        }

        return jsonResponse({'message': 'Error'}, 500);
      });

      final container = ProviderContainer(
        overrides: [dioProvider.overrideWithValue(dio)],
      );
      addTearDown(container.dispose);

      await container.read(cartProvider.future);

      // Intentar agregar una unidad extra cuando el stock máximo es 1
      final errorMessage = await container.read(cartProvider.notifier).addProduct(101, 2);

      // Debe retornar el mensaje exacto del servidor
      expect(errorMessage, contains('Stock insuficiente'));
      // CRÍTICO: El estado del carrito NO debe degradarse a AsyncError (defecto resuelto)
      final currentState = container.read(cartProvider);
      expect(currentState.hasError, isFalse);
      expect(currentState.asData?.value.items.length, equals(1));
      expect(currentState.asData?.value.total, equals(450.0));
    });

    // Integración 3 (AUT-05b): Resiliencia cuando el servidor no responde (Timeout / Sin conexión)
    test('AUT-05b: Muestra mensaje adecuado cuando el servidor no responde (connectionTimeout)', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://vintagevibe-backend.onrender.com/api/v1'));
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        if (options.method == 'GET' && options.path == ApiEndpoints.cart) {
          return jsonResponse({'id': 1, 'userId': 3, 'items': [], 'total': 0.0}, 200);
        }
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
          message: 'El servidor no respondió a tiempo.',
        );
      });

      final container = ProviderContainer(
        overrides: [dioProvider.overrideWithValue(dio)],
      );
      addTearDown(container.dispose);

      await container.read(cartProvider.future);

      final errorMessage = await container.read(cartProvider.notifier).addProduct(999, 1);

      expect(errorMessage, equals('No se pudo completar la operación en el carrito'));
      expect(container.read(cartProvider).hasError, isFalse);
    });

    // Integración 4 (AUT-06): Persistencia de sesión (AuthRepository + Dio + SecureStorage)
    test('AUT-06: AuthRepository.login persiste JWT y usuario en SecureStorage y logout los limpia', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://vintagevibe-backend.onrender.com/api/v1'));
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        if (options.method == 'POST' && options.path == ApiEndpoints.login) {
          expect(options.data, equals({
            'email': 'rvangel44gc@gmail.com',
            'password': 'password123',
          }));
          return jsonResponse({
            'id': 3,
            'token': 'eyJhbGciOiJIUzI1NiJ9.mock.jwt.token',
            'email': 'rvangel44gc@gmail.com',
            'firstName': 'Angel',
            'lastName': 'Gómez Castañón',
            'phone': '4428135204',
            'isActive': true,
            'role': 'ROLE_USER',
          }, 200);
        }
        if (options.method == 'POST' && options.path == ApiEndpoints.logout) {
          return jsonResponse({'message': 'Sesión cerrada'}, 200);
        }
        return jsonResponse({'message': 'Unauthorized'}, 401);
      });

      final authRepository = AuthRepository(dio);

      // 1. Ejecutar login
      final response = await authRepository.login(
        const LoginRequest(email: 'rvangel44gc@gmail.com', password: 'password123'),
      );
      expect(response.email, equals('rvangel44gc@gmail.com'));
      expect(response.token, equals('eyJhbGciOiJIUzI1NiJ9.mock.jwt.token'));

      // 2. Verificar persistencia real en SecureStorage
      final hasSession = await authRepository.hasSession();
      final storedToken = await SecureStorage.getToken();
      final storedUser = await authRepository.getStoredUser();

      expect(hasSession, isTrue);
      expect(storedToken, equals('eyJhbGciOiJIUzI1NiJ9.mock.jwt.token'));
      expect(storedUser, isNotNull);
      expect(storedUser!.firstName, equals('Angel'));
      expect(storedUser.role, equals('ROLE_USER'));

      // 3. Ejecutar logout y verificar limpieza total de persistencia
      await authRepository.logout();
      expect(await authRepository.hasSession(), isFalse);
      expect(await SecureStorage.getToken(), isNull);
      expect(await authRepository.getStoredUser(), isNull);
    });
  });
}
