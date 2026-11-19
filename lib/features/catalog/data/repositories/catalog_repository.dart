import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/local_catalog_database.dart';
import '../models/product.dart';

class CatalogRepository {
  final Dio _dio;
  final LocalCatalogDatabase _localDb;

  CatalogRepository(this._dio, {LocalCatalogDatabase? localDb})
      : _localDb = localDb ?? LocalCatalogDatabase.instance;

  Future<List<Product>> getProducts() async {
    try {
      final response = await _dio.get(ApiEndpoints.products);
      // Spring Boot Page<ProductDTO> format
      final List<dynamic> content = response.data['content'] ?? [];
      final products = content.map((json) => Product.fromJson(json)).toList();

      // Persistir catálogo estructurado en SQLite local (Práctica 4: caché offline)
      try {
        await _localDb.saveProducts(products);
      } catch (_) {
        // No bloquear el catálogo si SQLite no está disponible en la plataforma actual
      }
      return products;
    } on DioException {
      // Fallback offline: recuperar último catálogo persistido en SQLite local
      final cached = await _localDb.getAllProducts();
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  Future<Product> getProductById(int id) async {
    try {
      final response = await _dio.get('${ApiEndpoints.products}/$id');
      final product = Product.fromJson(response.data);
      try {
        await _localDb.insertProduct(product);
      } catch (_) {}
      return product;
    } on DioException {
      final cached = await _localDb.getProductById(id);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }
}
