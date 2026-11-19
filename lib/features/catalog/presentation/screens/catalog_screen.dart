import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/catalog_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_typography.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final screenWidth = mediaQuery.size.width;

    // Adaptar dinámicamente columnas y aspect ratio para prevenir desbordamientos RenderFlex
    final int crossAxisCount = screenWidth > 900
        ? 4
        : (isLandscape || screenWidth > 600 ? 3 : 2);
    final double childAspectRatio = isLandscape ? 0.72 : 0.65;

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('Explorar'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productsProvider);
          await ref.read(productsProvider.future);
        },
        child: productsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No hay prendas disponibles')),
                ],
              );
            }
            return GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final hasImage = product.images.isNotEmpty;
                
                return GestureDetector(
                  onTap: () => context.push('/product/${product.id}'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.grayLight.withOpacity(0.5), 
                          blurRadius: 10, 
                          offset: const Offset(0, 4)
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              image: hasImage 
                                  ? DecorationImage(image: NetworkImage(product.images.first), fit: BoxFit.cover)
                                  : null,
                              color: AppColors.grayLight,
                            ),
                            child: !hasImage ? const Center(child: Icon(Icons.image_not_supported, color: AppColors.gray)) : null,
                          ),
                        ),
                        // Details
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.brandName ?? 'Vintage',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.gray),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '\$${product.price.toStringAsFixed(2)}',
                                      style: AppTypography.bodyLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      final defaultVariant = product.variants.isNotEmpty 
                                          ? product.variants.first 
                                          : null;
                                      if (defaultVariant == null) return;

                                      if (defaultVariant.stock <= 0) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Esta prenda está agotada'),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: AppColors.error,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                        return;
                                      }

                                      final currentCart = ref.read(cartProvider).asData?.value;
                                      int inCartQty = 0;
                                      if (currentCart != null) {
                                        for (final item in currentCart.items) {
                                          if (item.variantId == defaultVariant.id) {
                                            inCartQty = item.quantity;
                                            break;
                                          }
                                        }
                                      }

                                      if (inCartQty >= defaultVariant.stock) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Ya tienes el máximo disponible (${defaultVariant.stock}) en tu carrito'),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: AppColors.accent,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                        return;
                                      }

                                      final error = await ref.read(cartProvider.notifier).addProduct(defaultVariant.id, 1);
                                      if (!context.mounted) return;
                                      if (error != null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(error),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: AppColors.error,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${product.name} agregado al carrito'),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: AppColors.success,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.add_shopping_cart, size: 20, color: AppColors.primaryDark),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (error, stack) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 120),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.gray),
                      const SizedBox(height: 12),
                      Text(
                        'No se pudieron cargar las prendas',
                        style: AppTypography.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Verifica tu conexión a internet o el estado del servidor e inténtalo de nuevo.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.gray),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(productsProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
