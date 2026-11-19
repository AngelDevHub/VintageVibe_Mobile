import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/address_model.dart';
import '../../data/repositories/address_repository.dart';

final addressesProvider = FutureProvider.autoDispose<List<AddressModel>>((ref) async {
  final repo = ref.watch(addressRepositoryProvider);
  return repo.getAddresses();
});
