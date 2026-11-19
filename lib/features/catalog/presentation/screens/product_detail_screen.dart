import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/catalog_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_typography.dart';
import '../../data/models/product.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int quantity = 1;
  ProductVariant? selectedVariant;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(singleProductProvider(widget.productId));

    return Scaffold(
      backgroundColor: AppColors.light,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.white.withOpacity(0.9), shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.dark),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.white.withOpacity(0.9), shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.favorite_border, color: AppColors.dark),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: AppColors.gray),
              const SizedBox(height: 16),
              Text('Prenda no encontrada o en proceso de carga', style: AppTypography.titleMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver al Catálogo'),
              ),
            ],
          ),
        ),
        data: (product) {
          if (selectedVariant == null && product.variants.isNotEmpty) {
            selectedVariant = product.variants.first;
          }

          final cartAsync = ref.watch(cartProvider);
          final cartData = cartAsync.asData?.value;
          int inCartQty = 0;
          if (cartData != null && selectedVariant != null) {
            for (final item in cartData.items) {
              if (item.variantId == selectedVariant!.id) {
                inCartQty = item.quantity;
                break;
              }
            }
          }
          final variantStock = selectedVariant?.stock ?? 0;
          final int diff = variantStock - inCartQty;
          final int remainingStock = diff < 0 ? 0 : diff;

          if (remainingStock > 0 && quantity > remainingStock) {
            quantity = remainingStock;
          }

          final hasImage = product.images.isNotEmpty;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image Hero
                      Stack(
                        children: [
                          Container(
                            height: 400,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.grayLight.withOpacity(0.3),
                              image: hasImage
                                  ? DecorationImage(image: NetworkImage(product.images.first), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: !hasImage 
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported, size: 80, color: AppColors.gray),
                                    SizedBox(height: 8),
                                    Text('Sin imagen'),
                                  ],
                                )
                              : null,
                          ),
                          if (product.conditionName != null)
                            Positioned(
                              bottom: 32,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: AppColors.shadowSm,
                                ),
                                child: Text(
                                  product.conditionName!,
                                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      // Details Container (Overlaps the image slightly)
                      Container(
                        transform: Matrix4.translationValues(0, -20, 0),
                        decoration: const BoxDecoration(
                          color: AppColors.light,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top info row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    product.brandName ?? 'Vintage',
                                    style: AppTypography.bodyMedium.copyWith(color: AppColors.gray, fontWeight: FontWeight.bold),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 18),
                                      const SizedBox(width: 4),
                                      Text('0.0 (0 reseñas)', style: AppTypography.bodySmall.copyWith(color: AppColors.gray)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Title and Price
                              Text(product.name, style: AppTypography.displayMedium.copyWith(color: AppColors.dark, height: 1.2)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'MXN ${product.price.toStringAsFixed(0)}',
                                    style: AppTypography.displayMedium.copyWith(color: AppColors.primary, fontSize: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  if (variantStock <= 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Text('Agotado', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                                    )
                                  else if (variantStock <= 2)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.amber.shade300),
                                      ),
                                      child: Text('¡Última(s) $variantStock pza(s)!', style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              
                              // Variants Selector (Mobile Optimized)
                              if (product.variants.isNotEmpty) ...[
                                Text(
                                  'Talla y Color',
                                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.dark),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 80,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: product.variants.length,
                                    itemBuilder: (context, index) {
                                      final v = product.variants[index];
                                      final isSelected = selectedVariant?.id == v.id;
                                      return GestureDetector(
                                        onTap: () => setState(() => selectedVariant = v),
                                        child: Container(
                                          margin: const EdgeInsets.only(right: 12),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.dark : AppColors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: isSelected ? AppColors.dark : AppColors.grayLight.withOpacity(0.5)),
                                            boxShadow: isSelected ? AppColors.shadowSm : null,
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '${v.size} · ${v.color}',
                                                style: AppTypography.bodyMedium.copyWith(
                                                  color: isSelected ? AppColors.white : AppColors.dark,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                v.stock <= 0 ? 'Agotado' : '${v.stock} disp.',
                                                style: AppTypography.bodySmall.copyWith(
                                                  color: v.stock <= 0
                                                      ? Colors.red.shade400
                                                      : (isSelected ? AppColors.grayLight : Colors.green.shade700),
                                                  fontSize: 11,
                                                  fontWeight: v.stock <= 0 ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Description
                              Text('Descripción', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.dark)),
                              const SizedBox(height: 8),
                              Text(
                                product.description.isEmpty ? 'Sin descripción detallada.' : product.description,
                                style: AppTypography.bodyMedium.copyWith(color: AppColors.gray, height: 1.5),
                              ),
                              const SizedBox(height: 32),
                              
                              // Trust Badges (Stacked for mobile)
                              _buildMobileTrustCard(
                                icon: Icons.shield_outlined,
                                title: 'Compra protegida',
                                subtitle: 'Flujo seguro y revisión antes del pago',
                              ),
                              const SizedBox(height: 12),
                              _buildMobileTrustCard(
                                icon: Icons.replay_outlined,
                                title: 'Devoluciones fáciles',
                                subtitle: 'Tienes hasta 30 días para gestionar cambios',
                              ),
                              const SizedBox(height: 32),
                              
                              // Bottom Info
                              Wrap(
                                spacing: 16,
                                runSpacing: 12,
                                children: [
                                  _buildSmallTrustIcon(Icons.local_shipping_outlined, 'Envío rápido'),
                                  _buildSmallTrustIcon(Icons.lock_outline, 'Compra segura'),
                                  _buildSmallTrustIcon(Icons.category_outlined, product.categoryName ?? 'Ropa'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom Action Bar (Sticky)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 10),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Quantity Selector Minimal
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.light,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.grayLight.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 20),
                              onPressed: (remainingStock > 0 && quantity > 1) ? () => setState(() => quantity--) : null,
                            ),
                            Text(
                              '${remainingStock > 0 ? quantity : 0}',
                              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: (remainingStock > 0 && quantity < remainingStock)
                                  ? () => setState(() => quantity++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Add to Cart Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (selectedVariant == null || remainingStock <= 0)
                              ? null
                              : () async {
                                  final error = await ref.read(cartProvider.notifier).addProduct(selectedVariant!.id, quantity);
                                  if (!context.mounted) return;
                                  if (error != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(error),
                                        backgroundColor: AppColors.error,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${quantity}x ${product.name} agregado al carrito'),
                                        backgroundColor: AppColors.success,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    setState(() {
                                      quantity = 1;
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.dark,
                            disabledBackgroundColor: AppColors.grayLight.withOpacity(0.4),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            variantStock <= 0
                                ? 'Agotado'
                                : (remainingStock <= 0
                                    ? 'En carrito (Máx $variantStock)'
                                    : 'Añadir'),
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileTrustCard({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.grayLight.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, size: 24, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.dark)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.gray, height: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallTrustIcon(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.gray),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.gray)),
      ],
    );
  }
}
