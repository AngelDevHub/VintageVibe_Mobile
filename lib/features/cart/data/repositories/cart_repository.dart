import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/cart_model.dart';

class CartRepository {
  final Dio _dio;

  CartRepository(this._dio);

  Future<CartModel> getCart() async {
    final response = await _dio.get(ApiEndpoints.cart);
    return CartModel.fromJson(response.data);
  }

  Future<CartModel> addItem(int variantId, int quantity) async {
    final response = await _dio.post(
      ApiEndpoints.cartItems,
      data: {'variantId': variantId, 'quantity': quantity},
    );
    return CartModel.fromJson(response.data);
  }

  Future<CartModel> updateItem(int itemId, int quantity) async {
    final response = await _dio.put(
      ApiEndpoints.cartItem(itemId),
      data: {'quantity': quantity},
    );
    return CartModel.fromJson(response.data);
  }

  Future<CartModel> removeItem(int itemId) async {
    final response = await _dio.delete(ApiEndpoints.cartItem(itemId));
    return CartModel.fromJson(response.data);
  }

  Future<void> clearCart() async {
    await _dio.delete(ApiEndpoints.cart);
  }
}

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.watch(dioProvider));
});
