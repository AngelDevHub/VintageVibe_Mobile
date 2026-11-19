import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/publish_repository.dart';
import '../../../catalog/data/models/product.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';

class PublishState {
  final bool isLoading;
  final String? error;
  final Product? publishedProduct;

  PublishState({this.isLoading = false, this.error, this.publishedProduct});
}

class PublishNotifier extends Notifier<PublishState> {
  @override
  PublishState build() => PublishState();

  Future<void> publish({
    required XFile image,
    required String title,
    required double price,
    required int brandId,
    required int categoryId,
    String? customBrand,
    required String condition,
    required String description,
  }) async {
    state = PublishState(isLoading: true);
    try {
      final repo = ref.read(publishRepositoryProvider);

      // 1. Subir imagen
      final imageUrl = await repo.uploadImage(image);

      // 2. Mapear condición a ID real en BD
      int conditionId = 1;
      if (condition == 'Nuevo con etiqueta') conditionId = 1;
      if (condition == 'Excelente') conditionId = 1;
      if (condition == 'Buen estado') conditionId = 2;
      if (condition == 'Usado') conditionId = 3;

      // Si eligió "Otra marca" (-1), conservamos la marca escrita en la descripción
      // y enviamos un brandId válido (1) para cumplir la FK en MySQL.
      final int effectiveBrandId = brandId > 0 ? brandId : 1;
      final String finalDescription = (customBrand != null && customBrand.trim().isNotEmpty)
          ? (description.trim().isEmpty
              ? 'Marca: ${customBrand.trim()}'
              : 'Marca: ${customBrand.trim()} · ${description.trim()}')
          : description.trim();

      // 3. Crear payload ProductDTO
      final data = {
        'name': title,
        'description': finalDescription,
        'price': price,
        'categoryId': categoryId > 0 ? categoryId : 1,
        'brandId': effectiveBrandId,
        'conditionId': conditionId,
        'images': [
          {
            'url': imageUrl,
            'primary': true,
          }
        ],
        'variants': [
          {
            'sku': 'C2C-${DateTime.now().millisecondsSinceEpoch}',
            'size': 'U',
            'color': 'N/A',
            'stock': 1,
            'price': price,
          }
        ],
      };

      final product = await repo.publishProduct(data);
      state = PublishState(isLoading: false, publishedProduct: product);

      ref.invalidate(myListingsProvider);
      ref.invalidate(productsProvider);
    } catch (e) {
      state = PublishState(isLoading: false, error: e.toString());
    }
  }
}

final publishProvider = NotifierProvider<PublishNotifier, PublishState>(() {
  return PublishNotifier();
});

final brandsProvider = FutureProvider<List<CatalogOption>>((ref) async {
  return ref.watch(publishRepositoryProvider).getBrands();
});

final categoriesProvider = FutureProvider<List<CatalogOption>>((ref) async {
  return ref.watch(publishRepositoryProvider).getCategories();
});

final myListingsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  return ref.watch(publishRepositoryProvider).getMyListings();
});
