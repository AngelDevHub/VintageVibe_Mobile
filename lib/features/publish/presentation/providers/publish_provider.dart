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
    required String brand,
    required String condition,
    required String description,
  }) async {
    state = PublishState(isLoading: true);
    try {
      final repo = ref.read(publishRepositoryProvider);
      
      // 1. Upload image
      final imageUrl = await repo.uploadImage(image);
      
      // 2. Map condition to ID (Mocked mapping based on your DB: 1=Excelente, 2=Buen estado, etc.)
      int conditionId = 1;
      if (condition == 'Nuevo con etiqueta') conditionId = 1;
      if (condition == 'Excelente') conditionId = 1;
      if (condition == 'Buen estado') conditionId = 2;
      if (condition == 'Usado') conditionId = 3;

      // 3. Create ProductDTO map
      final data = {
        'name': title,
        'description': description,
        'price': price,
        'categoryId': 1, // Default to a category since there's no UI for it yet
        'brandId': 1, // Default to a brand ID since there's no UI dropdown yet
        'conditionId': conditionId,
        'images': [
          {
            'url': imageUrl,
            'primary': true
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
        ]
      };

      final product = await repo.publishProduct(data);
      state = PublishState(isLoading: false, publishedProduct: product);
      
      // Refresh my listings
      ref.invalidate(myListingsProvider);
      ref.invalidate(productsProvider); // If catalog needs refresh
    } catch (e) {
      state = PublishState(isLoading: false, error: e.toString());
    }
  }
}

final publishProvider = NotifierProvider<PublishNotifier, PublishState>(() {
  return PublishNotifier();
});

final myListingsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  return ref.watch(publishRepositoryProvider).getMyListings();
});
