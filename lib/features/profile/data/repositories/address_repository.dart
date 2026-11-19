import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/address_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

final addressRepositoryProvider = Provider((ref) => AddressRepository(ref.read(dioProvider)));

class AddressRepository {
  final Dio _dio;
  AddressRepository(this._dio);

  Future<List<AddressModel>> getAddresses() async {
    final response = await _dio.get(ApiEndpoints.addresses);
    return (response.data as List).map((x) => AddressModel.fromJson(x)).toList();
  }

  Future<AddressModel> createAddress(AddressModel address) async {
    final response = await _dio.post(ApiEndpoints.addresses, data: address.toJson());
    return AddressModel.fromJson(response.data);
  }
}
