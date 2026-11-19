import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/order_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

final orderRepositoryProvider = Provider((ref) => OrderRepository(ref.read(dioProvider)));

class OrderRepository {
  final Dio _dio;
  OrderRepository(this._dio);

  Future<OrderModel> checkout(CheckoutRequest request) async {
    final response = await _dio.post(ApiEndpoints.checkout, data: request.toJson());
    return OrderModel.fromJson(response.data);
  }

  Future<List<OrderModel>> getMyOrders() async {
    final response = await _dio.get(ApiEndpoints.orders);
    return (response.data['content'] as List).map((x) => OrderModel.fromJson(x)).toList();
  }
}
