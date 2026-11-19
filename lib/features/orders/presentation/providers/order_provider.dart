import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';

final ordersProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getMyOrders();
});
