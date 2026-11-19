import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cart_model.dart';
import '../../data/repositories/cart_repository.dart';

class CartNotifier extends AsyncNotifier<CartModel> {
  @override
  Future<CartModel> build() async {
    return ref.read(cartRepositoryProvider).getCart();
  }

  /// Agrega un producto al carrito. Retorna null si fue exitoso o un mensaje de error si falló.
  Future<String?> addProduct(int variantId, int quantity) async {
    final previousState = state;
    try {
      final updatedCart = await ref.read(cartRepositoryProvider).addItem(variantId, quantity);
      state = AsyncValue.data(updatedCart);
      return null;
    } catch (e) {
      // Conservar el estado previo del carrito para no dejar la vista en pantalla de error
      state = previousState;
      return _extractErrorMessage(e);
    }
  }

  /// Actualiza la cantidad de un ítem en el carrito. Retorna null si fue exitoso o un mensaje de error si falló.
  Future<String?> updateQuantity(int itemId, int newQuantity) async {
    if (newQuantity <= 0) {
      return removeItem(itemId);
    }
    final previousState = state;
    try {
      final updatedCart = await ref.read(cartRepositoryProvider).updateItem(itemId, newQuantity);
      state = AsyncValue.data(updatedCart);
      return null;
    } catch (e) {
      state = previousState;
      return _extractErrorMessage(e);
    }
  }

  /// Elimina un ítem del carrito.
  Future<String?> removeItem(int itemId) async {
    final previousState = state;
    try {
      final updatedCart = await ref.read(cartRepositoryProvider).removeItem(itemId);
      state = AsyncValue.data(updatedCart);
      return null;
    } catch (e) {
      state = previousState;
      return _extractErrorMessage(e);
    }
  }

  /// Vacía el carrito completo.
  Future<void> clearCart() async {
    final previousState = state;
    try {
      await ref.read(cartRepositoryProvider).clearCart();
      state = AsyncValue.data(CartModel(id: 0, userId: 0, items: [], total: 0.0));
    } catch (e) {
      state = previousState;
    }
  }

  String _extractErrorMessage(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }
    return 'No se pudo completar la operación en el carrito';
  }
}

final cartProvider = AsyncNotifierProvider<CartNotifier, CartModel>(() {
  return CartNotifier();
});
