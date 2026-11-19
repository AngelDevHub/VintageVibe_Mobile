import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/models/product.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(dioProvider));
});

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(catalogRepositoryProvider);
  return repository.getProducts();
});

final singleProductProvider = FutureProvider.family<Product, int>((ref, id) async {
  final productsAsync = ref.watch(productsProvider);
  if (productsAsync.hasValue) {
    final matches = productsAsync.value!.where((p) => p.id == id);
    if (matches.isNotEmpty) return matches.first;
  }
  final repository = ref.watch(catalogRepositoryProvider);
  return repository.getProductById(id);
});
