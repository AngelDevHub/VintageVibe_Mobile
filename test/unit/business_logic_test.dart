import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/models/auth_models.dart';
import 'package:mobile/features/cart/data/models/cart_model.dart';
import 'package:mobile/features/publish/presentation/screens/publish_screen.dart';

/// Función auxiliar que replica la regla de negocio crítica de stock restante
/// aplicada en ProductDetailScreen y CatalogScreen.
int calculateRemainingStock({required int variantStock, required int inCartQty}) {
  if (variantStock < 0 || inCartQty < 0) {
    throw ArgumentError('El stock y la cantidad en carrito no pueden ser negativos.');
  }
  final diff = variantStock - inCartQty;
  return diff < 0 ? 0 : diff;
}

void main() {
  group('Fase 2 - Pruebas Unitarias de Lógica de Negocio Crítica (VintageVibe)', () {
    // 1. Entrada válida
    test('AUT-01: Entrada válida - Validador de precios acepta montos con formato monetario', () {
      expect(validateAndSanitizePrice('\$250.50'), isNull);
      expect(validateAndSanitizePrice('1200'), isNull);
      expect(validateAndSanitizePrice('\$85,99'), isNull);
    });

    // 2. Entrada vacía o nula
    test('AUT-01b: Entrada vacía o nula - Rechaza valores nulos, vacíos o solo espacios', () {
      expect(validateAndSanitizePrice(null), equals('Requerido'));
      expect(validateAndSanitizePrice(''), equals('Requerido'));
      expect(validateAndSanitizePrice('    '), equals('Requerido'));
    });

    // 3. Valores fuera de rango
    test('AUT-02: Valores fuera de rango - Rechaza precios en cero, negativos o no numéricos', () {
      expect(validateAndSanitizePrice('0'), equals('El precio debe ser mayor a 0'));
      expect(validateAndSanitizePrice('\$0.00'), equals('El precio debe ser mayor a 0'));
      expect(validateAndSanitizePrice('-45.50'), equals('El precio debe ser mayor a 0'));
      expect(validateAndSanitizePrice('abc'), equals('El precio debe ser mayor a 0'));
    });

    // 4. Valores fuera de rango (Control de inventario / stock)
    test('AUT-02b: Valores fuera de rango - Stock restante nunca es negativo si inCart >= stock', () {
      expect(calculateRemainingStock(variantStock: 1, inCartQty: 1), equals(0));
      expect(calculateRemainingStock(variantStock: 1, inCartQty: 3), equals(0));
      expect(calculateRemainingStock(variantStock: 5, inCartQty: 2), equals(3));
    });

    // 5. Resultado esperado (Cálculo de subtotales y deserialización de CartModel)
    test('AUT-03: Resultado esperado - CartModel y CartItemModel calculan totales correctamente', () {
      final json = {
        'id': 10,
        'userId': 3,
        'total': 170.0,
        'items': [
          {
            'id': 1,
            'variantId': 42,
            'productName': 'Chaqueta Levi\'s 90s',
            'variantSku': 'LEV-90-M',
            'size': 'M',
            'color': 'Azul',
            'price': 85.0,
            'quantity': 2,
            'stock': 3,
          },
        ],
      };

      final cart = CartModel.fromJson(json);

      expect(cart.id, equals(10));
      expect(cart.userId, equals(3));
      expect(cart.items.length, equals(1));
      expect(cart.items.first.subtotal, equals(170.0));
      expect(cart.total, equals(170.0));
    });

    // 6. Resultado esperado (Deserialización de AuthResponse y defaults seguros)
    test('AUT-03b: Resultado esperado - CartModel maneja lista items nula sin colapsar', () {
      final json = {
        'id': 11,
        'userId': 3,
        'items': null,
        'total': null,
      };

      final cart = CartModel.fromJson(json);

      expect(cart.items, isEmpty);
      expect(cart.total, equals(0.0));
    });

    // 7. Manejo de excepciones
    test('AUT-03c: Manejo de excepciones - Lanza ArgumentError ante stock o cantidad negativos', () {
      expect(
        () => calculateRemainingStock(variantStock: -1, inCartQty: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => calculateRemainingStock(variantStock: 2, inCartQty: -5),
        throwsA(isA<ArgumentError>()),
      );
    });

    // 8. Manejo de excepciones en deserialización corrupta
    test('AUT-03d: Manejo de excepciones - Payload JSON corrupto sin id obligatorio lanza TypeError', () {
      final invalidJson = <String, dynamic>{
        'userId': 3,
        'items': [],
        'total': 0.0,
      };

      expect(
        () => CartModel.fromJson(invalidJson),
        throwsA(isA<TypeError>()),
      );

      final authJson = {
        'id': 3,
        'token': 'jwt-mock-token',
        'email': 'rvangel44gc@gmail.com',
        'firstName': 'Angel',
        'lastName': 'Gómez',
        'role': 'ROLE_USER',
      };
      final auth = AuthResponse.fromJson(authJson);
      expect(auth.email, equals('rvangel44gc@gmail.com'));
      expect(auth.token, equals('jwt-mock-token'));
    });
  });
}
