import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../catalog/data/models/product.dart';

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

  Future<Product> publishProduct(Map<String, dynamic> productData) async {
    final response = await _dio.post(ApiEndpoints.c2cListings, data: productData);
    return Product.fromJson(response.data);
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
