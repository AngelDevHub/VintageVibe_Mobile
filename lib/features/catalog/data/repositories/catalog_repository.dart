import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/local_catalog_database.dart';
import '../models/product.dart';
import '../models/review_model.dart';

class CatalogRepository {
  static const String _webCacheKey = 'vv_catalog_offline_cache_v1';

  final Dio _dio;
  final LocalCatalogDatabase _localDb;

  CatalogRepository(this._dio, {LocalCatalogDatabase? localDb})
      : _localDb = localDb ?? LocalCatalogDatabase.instance;

  Future<void> _saveWebCache(List<dynamic> rawContent) async {
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_webCacheKey, jsonEncode(rawContent));
    } catch (_) {}
  }

  Future<List<Product>> _loadWebCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_webCacheKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Product>> getProducts() async {
    try {
      final response = await _dio.get(ApiEndpoints.products);
      // Spring Boot Page<ProductDTO> format
      final List<dynamic> content = response.data['content'] ?? [];
      final products = content.map((json) => Product.fromJson(json)).toList();

      // Persistir catálogo estructurado en SQLite local (Android/iOS nativo)
      try {
        await _localDb.saveProducts(products);
      } catch (_) {
        // No bloquear el catálogo si SQLite no está disponible en la plataforma actual
      }
      // Persistir caché offline en LocalStorage/SharedPreferences para PWA Web
      await _saveWebCache(content);
      return products;
    } on DioException {
      // Fallback offline 1: SQLite local (Android/iOS)
      final cached = await _localDb.getAllProducts();
      if (cached.isNotEmpty) {
        return cached;
      }
      // Fallback offline 2: SharedPreferences / LocalStorage (PWA Web)
      final webCached = await _loadWebCache();
      if (webCached.isNotEmpty) {
        return webCached;
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
      final webCached = await _loadWebCache();
      for (final item in webCached) {
        if (item.id == id) return item;
      }
      rethrow;
    }
  }

  Future<List<ReviewModel>> getProductReviews(int productId) async {
    try {
      final response = await _dio.get(ApiEndpoints.reviewsByProduct(productId));
      final dynamic raw = response.data;
      final List<dynamic> content = (raw is Map && raw['content'] is List)
          ? raw['content'] as List<dynamic>
          : (raw is List ? raw : []);
      return content.map((json) => ReviewModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<ReviewModel> createReview({
    required int productId,
    required int rating,
    required String comment,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.reviews,
      data: {
        'productId': productId,
        'rating': rating,
        'comment': comment,
      },
    );
    return ReviewModel.fromJson(response.data as Map<String, dynamic>);
  }
}
