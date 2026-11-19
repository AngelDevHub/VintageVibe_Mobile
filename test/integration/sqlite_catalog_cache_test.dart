import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/local_catalog_database.dart';
import 'package:mobile/features/catalog/data/models/product.dart';
import 'package:mobile/features/catalog/data/repositories/catalog_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _ToggleOfflineAdapter implements HttpClientAdapter {
  bool isOffline = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (isOffline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'Sin conexión a internet',
      );
    }

    return ResponseBody.fromString(
      jsonEncode({
        'content': [
          {
            'id': 1,
            'name': 'Chaqueta Denim 90s',
            'description': 'Mezclilla gruesa original',
            'price': 650.0,
            'categoryName': 'Chaquetas',
            'brandName': 'Levi\'s',
            'conditionName': 'Excelente',
            'sellerName': 'Angel',
            'images': [
              {'url': 'https://res.cloudinary.com/demo/image/upload/chaqueta.jpg'},
            ],
            'variants': [
              {'id': 11, 'sku': 'LEV-90-M', 'size': 'M', 'color': 'Azul', 'stock': 1},
            ],
          },
        ],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  sqfliteFfiInit();

  group('Práctica 4 - Almacenamiento Estructurado SQLite (CRUD + Fallback Offline)', () {
    late LocalCatalogDatabase localDb;

    setUp(() {
      localDb = LocalCatalogDatabase(
        databaseFactory: databaseFactoryFfi,
        customPath: inMemoryDatabasePath,
      );
    });

    tearDown(() async {
      await localDb.close();
    });

    test('P4-01: INSERT y SELECT estructurado de 3 prendas en SQLite local', () async {
      final items = [
        Product(id: 1, name: 'Sudadera Beige 90s', description: 'Algodón pesado', price: 450.0),
        Product(id: 2, name: 'Gorra Vintage Negra', description: 'Bordado clásico', price: 220.0),
        Product(id: 3, name: 'Pantalón Cargo Verde', description: 'Corte recto', price: 540.0),
      ];

      await localDb.saveProducts(items);
      final stored = await localDb.getAllProducts();

      expect(stored.length, equals(3));
      expect(stored[0].name, equals('Sudadera Beige 90s'));
      expect(stored[2].price, equals(540.0));
    });

    test('P4-02: UPDATE modifica un registro existente en SQLite y conserva el cambio', () async {
      await localDb.insertProduct(
        Product(id: 10, name: 'Playera Retro', description: 'Talla M', price: 180.0),
      );

      final updated = Product(id: 10, name: 'Playera Retro Edición 95', description: 'Talla M', price: 210.0);
      final rowsAffected = await localDb.updateProduct(updated);
      final fetched = await localDb.getProductById(10);

      expect(rowsAffected, equals(1));
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Playera Retro Edición 95'));
      expect(fetched.price, equals(210.0));
    });

    test('P4-03: DELETE elimina una prenda por ID en SQLite local', () async {
      await localDb.insertProduct(
        Product(id: 20, name: 'Camisa Franela', description: 'Cuadros rojos', price: 300.0),
      );

      final deleted = await localDb.deleteProduct(20);
      final fetched = await localDb.getProductById(20);

      expect(deleted, equals(1));
      expect(fetched, isNull);
    });

    test('P4-04: Integración CatalogRepository sincroniza SQLite online y responde offline al caer la red', () async {
      final adapter = _ToggleOfflineAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://vintagevibe-backend.onrender.com/api/v1'));
      dio.httpClientAdapter = adapter;

      final repo = CatalogRepository(dio, localDb: localDb);

      // 1. Online: descarga de la API y guarda en SQLite
      final onlineProducts = await repo.getProducts();
      expect(onlineProducts.length, equals(1));
      expect(onlineProducts.first.name, equals('Chaqueta Denim 90s'));

      // 2. Offline: cae la red y CatalogRepository recupera desde SQLite sin lanzar error
      adapter.isOffline = true;
      final offlineProducts = await repo.getProducts();
      expect(offlineProducts.length, equals(1));
      expect(offlineProducts.first.name, equals('Chaqueta Denim 90s'));
      expect(offlineProducts.first.variants.first.sku, equals('LEV-90-M'));
    });
  });
}
