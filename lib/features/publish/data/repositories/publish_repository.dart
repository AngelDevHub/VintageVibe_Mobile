import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../catalog/data/models/product.dart';

class CatalogOption {
  final int id;
  final String name;

  const CatalogOption({required this.id, required this.name});

  factory CatalogOption.fromJson(Map<String, dynamic> json) {
    return CatalogOption(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
    );
  }
}

class PublishRepository {
  final Dio _dio;

  PublishRepository(this._dio);

  Future<String> uploadImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.name.isNotEmpty ? file.name : 'vintage_garment.jpg',
      ),
    });
    final response = await _dio.post('/images/upload', data: formData);
    return response.data['url'] as String;
  }

  Future<List<CatalogOption>> getBrands() async {
    final response = await _dio.get(ApiEndpoints.brands);
    final raw = response.data is List
        ? response.data as List
        : (response.data is Map && response.data['content'] is List
            ? response.data['content'] as List
            : <dynamic>[]);
    return raw
        .map((e) => CatalogOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CatalogOption>> getCategories() async {
    final response = await _dio.get(ApiEndpoints.categories);
    final raw = response.data is List
        ? response.data as List
        : (response.data is Map && response.data['content'] is List
            ? response.data['content'] as List
            : <dynamic>[]);
    return raw
        .map((e) => CatalogOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Product> publishProduct(Map<String, dynamic> productData) async {
    final response = await _dio.post(ApiEndpoints.c2cListings, data: productData);
    return Product.fromJson(response.data);
  }

  Future<Product> updateListing(int id, Map<String, dynamic> productData) async {
    final response = await _dio.put('${ApiEndpoints.c2cListings}/$id', data: productData);
    return Product.fromJson(response.data);
  }

  Future<void> deleteListing(int id) async {
    await _dio.delete('${ApiEndpoints.c2cListings}/$id');
  }

  Future<List<Product>> getMyListings() async {
    final response = await _dio.get(ApiEndpoints.c2cMyListings);
    final data = response.data['content'] as List;
    return data.map((json) => Product.fromJson(json)).toList();
  }
}

final publishRepositoryProvider = Provider<PublishRepository>((ref) {
  return PublishRepository(ref.watch(dioProvider));
});
