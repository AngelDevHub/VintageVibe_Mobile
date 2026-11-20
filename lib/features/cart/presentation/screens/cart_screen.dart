import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_provider.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_typography.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    
    final double goal = 3000.0;

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('Mi Carrito'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: cartAsync.when(
        data: (cart) {
          if (cart.items.isEmpty) {
            return _buildEmptyState(context);
          }

          final double progress = (cart.total / goal).clamp(0.0, 1.0);
          final double remaining = (goal - cart.total).clamp(0.0, goal);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image Placeholder
                          Container(
                            width: 80,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.light,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: Icon(Icons.image, color: AppColors.grayLight)),
                          ),
                          const SizedBox(width: 12),
                          
                          // Info Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title & Delete
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.productName, 
                                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.dark),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => cartNotifier.removeItem(item.id),
                                      child: const Icon(Icons.close, size: 20, color: AppColors.gray),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                
                                // Variant Info & Stock Badge
                                Row(
                                  children: [
                                    Text('${item.size} · ${item.color}', style: AppTypography.bodySmall.copyWith(color: AppColors.gray)),
                                    if (item.stock <= 2) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.amber.shade300),
                                        ),
                                        child: Text(
                                          'Solo ${item.stock} disp.',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                // Price & Quantity Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'MXN ${item.price.toStringAsFixed(0)}', 
                                      style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                    ),
                                    
                                    // Minimal Mobile Quantity Selector
                                    Container(
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppColors.light,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            icon: const Icon(Icons.remove, size: 16, color: AppColors.dark),
                                            onPressed: () {
                                              if (item.quantity > 1) {
                                                cartNotifier.updateQuantity(item.id, item.quantity - 1);
                                              } else {
                                                cartNotifier.removeItem(item.id);
                                              }
                                            },
                                          ),
                                          Text('${item.quantity}', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            icon: Icon(
                                              Icons.add, 
                                              size: 16, 
                                              color: item.quantity >= item.stock ? AppColors.grayLight : AppColors.dark,
                                            ),
                                            onPressed: item.quantity < item.stock
                                                ? () async {
                                                    final error = await cartNotifier.updateQuantity(item.id, item.quantity + 1);
                                                    if (error != null && context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text(error), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
                                                      );
                                                    }
                                                  }
                                                : () {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Solo hay ${item.stock} unidad(es) disponible(s) de esta prenda'),
                                                        behavior: SnackBarBehavior.floating,
                                                        duration: const Duration(seconds: 2),
                                                      ),
                                                    );
                                                  },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              // Bottom Checkout Panel (Sticky)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, -4), blurRadius: 10)],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress Bar Mini
                      if (remaining > 0)
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: AppColors.light,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('Faltan \$${remaining.toStringAsFixed(0)} para envío gratis', style: AppTypography.bodySmall.copyWith(color: AppColors.gray, fontSize: 10)),
                          ],
                        ),
                      const SizedBox(height: 16),
                      
                      // Total Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total', style: AppTypography.bodyMedium.copyWith(color: AppColors.gray)),
                              Text('MXN ${cart.total.toStringAsFixed(0)}', style: AppTypography.displayMedium.copyWith(color: AppColors.dark, fontSize: 24)),
                            ],
                          ),
                          
                          // Checkout Button
                          ElevatedButton(
                            onPressed: () => context.push('/checkout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.dark,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Checkout', style: AppTypography.bodyMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_ios, color: AppColors.white, size: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Espacio de separación para no ser cubierto por la barra de navegación flotante
                      const SizedBox(height: 76),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.gray),
                const SizedBox(height: 16),
                Text('No se pudo sincronizar el carrito', style: AppTypography.titleMedium),
                const SizedBox(height: 8),
                Text(
                  e.toString().contains('DioException') ? 'Verifica tu conexión y vuelve a intentar.' : e.toString(),
                  style: AppTypography.bodySmall.copyWith(color: AppColors.gray),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(cartProvider),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dark,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.grayLight),
            const SizedBox(height: 24),
            Text('Tu carrito está vacío', style: AppTypography.displayMedium.copyWith(color: AppColors.dark)),
            const SizedBox(height: 12),
            Text(
              'Agrega algunas prendas vintage para empezar tu colección.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.gray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dark,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Explorar prendas', style: AppTypography.bodyMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
