import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/catalog/presentation/screens/catalog_screen.dart';
import 'package:mobile/features/catalog/presentation/providers/catalog_provider.dart';
import 'package:mobile/features/catalog/data/models/product.dart';
import 'package:mobile/features/publish/presentation/screens/publish_screen.dart';

void main() {
  group('Pruebas de Widgets y UI - CatalogScreen (Mobile Flutter)', () {
    testWidgets('CP-MOB-01: Muestra mensaje cuando el catálogo de productos está vacío',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productsProvider.overrideWithValue(const AsyncValue.data([])),
          ],
          child: const MaterialApp(
            home: CatalogScreen(),
          ),
        ),
      );

      // Renderiza el frame
      await tester.pump();

      // Debe mostrar el mensaje de catálogo vacío
      expect(find.text('No hay prendas disponibles'), findsOneWidget);
      expect(find.text('Explorar'), findsOneWidget);
    });

    testWidgets('CP-MOB-02: Renderiza tarjetas de prendas cuando el catálogo tiene datos',
        (WidgetTester tester) async {
      final mockProducts = [
        Product(
          id: 1,
          name: 'Chaqueta Denim Vintage 90s',
          description: 'Excelente estado, corte clásico.',
          price: 85.0,
          categoryName: 'Chaquetas',
          brandName: 'Levis',
          conditionName: 'Excelente',
          sellerName: 'RetroShop',
          images: [],
          variants: [],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productsProvider.overrideWithValue(AsyncValue.data(mockProducts)),
          ],
          child: const MaterialApp(
            home: CatalogScreen(),
          ),
        ),
      );

      await tester.pump();

      // Debe renderizar el nombre de la prenda y el precio
      expect(find.text('Chaqueta Denim Vintage 90s'), findsOneWidget);
      expect(find.text('\$85.00'), findsOneWidget);
    });
  });

  group('Pruebas Unitarias White Box - Validador de Precios C2C (ST-01)', () {
    test('TC-VAL-01: Rechaza entrada nula', () {
      expect(validateAndSanitizePrice(null), 'Requerido');
    });

    test('TC-VAL-02: Rechaza entrada con solo espacios en blanco', () {
      expect(validateAndSanitizePrice('   '), 'Requerido');
    });

    test('TC-VAL-03: Rechaza caracteres alfanuméricos no numéricos', () {
      expect(validateAndSanitizePrice('abc'), 'El precio debe ser mayor a 0');
    });

    test('TC-VAL-04: Rechaza precio en cero con símbolo de moneda (\$0.00)', () {
      expect(validateAndSanitizePrice('\$0.00'), 'El precio debe ser mayor a 0');
    });

    test('TC-VAL-05: Rechaza precio negativo (-0.01)', () {
      expect(validateAndSanitizePrice('-0.01'), 'El precio debe ser mayor a 0');
    });

    test('TC-VAL-06: Acepta valor límite inferior válido (\$0.01)', () {
      expect(validateAndSanitizePrice('\$0.01'), isNull);
    });

    test('TC-VAL-07: Acepta precio con formato de coma decimal y símbolo (\$150,50)', () {
      expect(validateAndSanitizePrice('\$150,50'), isNull);
    });
  });
}
