import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/data/repositories/order_repository.dart';
import 'cart_provider.dart';

final checkoutProvider = NotifierProvider<CheckoutNotifier, CheckoutState>(() {
  return CheckoutNotifier();
});

class CheckoutState {
  final bool isLoading;
  final String? error;
  final OrderModel? successOrder;

  CheckoutState({this.isLoading = false, this.error, this.successOrder});

  CheckoutState copyWith({bool? isLoading, String? error, OrderModel? successOrder}) {
    return CheckoutState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successOrder: successOrder ?? this.successOrder,
    );
  }
}

class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => CheckoutState();

  Future<void> submitOrder({required int addressId, required String paymentMethod}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final request = CheckoutRequest(addressId: addressId, paymentMethod: paymentMethod);
      final order = await ref.read(orderRepositoryProvider).checkout(request);
      
      // Clear cart on success
      await ref.read(cartProvider.notifier).clearCart();
      
      state = state.copyWith(isLoading: false, successOrder: order);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
