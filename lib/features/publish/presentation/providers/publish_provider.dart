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

  int _mapConditionToId(String condition) {
    if (condition == 'Nuevo con etiqueta') return 1;
    if (condition == 'Excelente') return 1;
    if (condition == 'Buen estado' || condition == 'Muy Bueno') return 2;
    if (condition == 'Usado' || condition == 'Bueno') return 3;
    return 1;
  }

  String _composeDescription({
    String? customBrand,
    String? customCategory,
    required String description,
  }) {
    final prefixes = <String>[];
    if (customBrand != null && customBrand.trim().isNotEmpty) {
      prefixes.add('Marca: ${customBrand.trim()}');
    }
    if (customCategory != null && customCategory.trim().isNotEmpty) {
      prefixes.add('Categoría: ${customCategory.trim()}');
    }
    final cleanDesc = description.trim();
    if (prefixes.isEmpty) return cleanDesc;
    if (cleanDesc.isEmpty) return prefixes.join(' · ');
    return '${prefixes.join(' · ')} · $cleanDesc';
  }

  Future<void> publish({
    required XFile image,
    required String title,
    required double price,
    required int stock,
    required int brandId,
    required int categoryId,
    String? customBrand,
    String? customCategory,
    required String condition,
    required String description,
  }) async {
    state = PublishState(isLoading: true);
    try {
      final repo = ref.read(publishRepositoryProvider);

      // 1. Subir imagen
      final imageUrl = await repo.uploadImage(image);

      // 2. Mapear condición y metadatos personalizados
      final conditionId = _mapConditionToId(condition);
      final effectiveBrandId = brandId > 0 ? brandId : 1;
      final effectiveCategoryId = categoryId > 0 ? categoryId : 1;
      final finalDescription = _composeDescription(
        customBrand: customBrand,
        customCategory: customCategory,
        description: description,
      );

      // 3. Crear payload ProductDTO
      final data = {
        'name': title,
        'description': finalDescription,
        'price': price,
        'categoryId': effectiveCategoryId,
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
            'stock': stock > 0 ? stock : 1,
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

  /// Edita una publicación existente del usuario autenticado (PUT /api/v1/c2c/listings/{id})
  Future<String?> updateListing({
    required Product existing,
    required String title,
    required double price,
    required int stock,
    required String size,
    required int brandId,
    required int categoryId,
    String? customBrand,
    String? customCategory,
    required String condition,
    required String description,
  }) async {
    try {
      final repo = ref.read(publishRepositoryProvider);
      final conditionId = _mapConditionToId(condition);
      final effectiveBrandId = brandId > 0 ? brandId : 1;
      final effectiveCategoryId = categoryId > 0 ? categoryId : 1;
      final finalDescription = _composeDescription(
        customBrand: customBrand,
        customCategory: customCategory,
        description: description,
      );

      final firstVariant = existing.variants.isNotEmpty ? existing.variants.first : null;

      final data = {
        'name': title.trim(),
        'description': finalDescription,
        'price': price,
        'categoryId': effectiveCategoryId,
        'brandId': effectiveBrandId,
        'conditionId': conditionId,
        'images': existing.images
            .asMap()
            .entries
            .map((e) => {'url': e.value, 'primary': e.key == 0})
            .toList(),
        'variants': [
          {
            if (firstVariant != null) 'id': firstVariant.id,
            'sku': firstVariant?.sku ?? 'C2C-${DateTime.now().millisecondsSinceEpoch}',
            'size': size.trim().isEmpty ? 'U' : size.trim(),
            'color': firstVariant?.color ?? 'N/A',
            'stock': stock >= 0 ? stock : 0,
            'price': price,
          }
        ],
      };

      await repo.updateListing(existing.id, data);
      ref.invalidate(myListingsProvider);
      ref.invalidate(productsProvider);
      return null;
    } catch (e) {
      return 'No se pudo actualizar la publicación: $e';
    }
  }

  Future<String?> deleteListing(int id) async {
    try {
      await ref.read(publishRepositoryProvider).deleteListing(id);
      ref.invalidate(myListingsProvider);
      ref.invalidate(productsProvider);
      return null;
    } catch (e) {
      return 'No se pudo eliminar la publicación: $e';
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
