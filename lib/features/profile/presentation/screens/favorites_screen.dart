import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_typography.dart';
import '../../../../shared/widgets/ios_pressable.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../../../catalog/presentation/providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoritesProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('Mis Favoritos'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, size: 20, color: AppColors.dark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: productsAsync.when(
        loading: () => const Center(
          child: CupertinoActivityIndicator(radius: 12, color: AppColors.dark),
        ),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.wifi_slash, size: 36, color: AppColors.gray),
              const SizedBox(height: 12),
              Text('No se pudieron cargar tus favoritos', style: AppTypography.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(productsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (products) {
          final favorites = products.where((p) => favoriteIds.contains(p.id)).toList();

          if (favorites.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.heart, size: 42, color: AppColors.gray),
                    const SizedBox(height: 16),
                    Text('Aún no tienes prendas guardadas', style: AppTypography.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Toca el corazón en cualquier prenda del catálogo para guardarla aquí.',
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Explorar catálogo'),
                    ),
                  ],
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.54,
              crossAxisSpacing: 16,
              mainAxisSpacing: 24,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final product = favorites[index];
              final hasImage = product.images.isNotEmpty;

              return IosPressable(
                onTap: () => context.push('/product/${product.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 3 / 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border, width: 0.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: hasImage
                            ? Image.network(
                                product.images.first,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(CupertinoIcons.photo, size: 28, color: AppColors.gray),
                                ),
                              )
                            : const Center(
                                child: Icon(CupertinoIcons.photo, size: 28, color: AppColors.gray),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: AppTypography.titleSmall.copyWith(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => ref.read(favoritesProvider.notifier).toggleFavorite(product.id),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 6, top: 2),
                            child: Icon(CupertinoIcons.heart_fill, size: 16, color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.brandName ?? 'Vintage',
                      style: AppTypography.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text('\$${product.price.toStringAsFixed(2)}', style: AppTypography.priceSmall),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
