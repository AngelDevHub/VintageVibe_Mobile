import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_typography.dart';
import '../../../../shared/widgets/ios_pressable.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../data/models/product.dart';
import '../providers/catalog_provider.dart';
import '../providers/favorites_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int quantity = 1;
  ProductVariant? selectedVariant;

  void _showSizeGuideModal(BuildContext context, String sizeLabel) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.light,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Guía de medidas vintage', style: AppTypography.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'En ropa vintage la talla en etiqueta puede variar respecto al tallaje actual. Verifica las medidas reales en plano:',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      _MeasurementRow(label: 'Talla en etiqueta', value: sizeLabel),
                      const Divider(height: 20),
                      const _MeasurementRow(label: 'Ancho (axila a axila)', value: '54 – 58 cm aprox.'),
                      const Divider(height: 20),
                      const _MeasurementRow(label: 'Largo total (hombro a ruedo)', value: '68 – 72 cm aprox.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(singleProductProvider(widget.productId));
    final isFavorite = ref.watch(favoritesProvider).contains(widget.productId);

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        backgroundColor: AppColors.light,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, size: 20, color: AppColors.dark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Detalle', style: AppTypography.titleMedium),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              size: 20,
              color: isFavorite ? AppColors.error : AppColors.dark,
            ),
            onPressed: () {
              ref.read(favoritesProvider.notifier).toggleFavorite(widget.productId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavorite ? 'Eliminado de tus favoritos' : 'Guardado en tus favoritos',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Guardar en favoritos',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: productAsync.when(
        loading: () => const Center(
          child: CupertinoActivityIndicator(radius: 12, color: AppColors.dark),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.search, size: 36, color: AppColors.gray),
                const SizedBox(height: 16),
                Text(
                  'Prenda no encontrada o en proceso de carga',
                  style: AppTypography.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Volver al Catálogo'),
                ),
              ],
            ),
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
          final availabilityText = variantStock <= 0
              ? 'Agotado'
              : (variantStock == 1 ? 'Pieza única' : '$variantStock disponibles');
          final availabilityColor = variantStock <= 0
              ? AppColors.error
              : (variantStock == 1 ? AppColors.secondary : AppColors.gray);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Fotografía limpia en proporción vertical 3:4 sin etiquetas encima
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border, width: 0.5),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: hasImage
                                ? Image.network(
                                    product.images.first,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(CupertinoIcons.photo, size: 40, color: AppColors.gray),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(CupertinoIcons.photo, size: 40, color: AppColors.gray),
                                  ),
                          ),
                        ),
                      ),

                      // Bloque editorial de información
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Marca + Disponibilidad discreta
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  (product.brandName ?? 'Vintage Seleccionado').toUpperCase(),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.gray,
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  availabilityText,
                                  style: AppTypography.labelMedium.copyWith(
                                    color: availabilityColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Título editorial
                            Text(
                              product.name,
                              style: AppTypography.displaySmall.copyWith(
                                color: AppColors.dark,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Precio firme
                            Text(
                              '\$${product.price.toStringAsFixed(2)} MXN',
                              style: AppTypography.price,
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 20),

                            // Datos clave de ropa vintage (Condición, Talla / Medidas, Origen)
                            _VintageSpecRow(
                              icon: CupertinoIcons.tag,
                              label: 'Condición',
                              value: product.conditionName ?? 'Excelente estado vintage',
                            ),
                            const SizedBox(height: 12),
                            _VintageSpecRow(
                              icon: CupertinoIcons.square_grid_2x2,
                              label: 'Categoría',
                              value: product.categoryName ?? 'Moda circular',
                            ),
                            if (product.sellerName != null) ...[
                              const SizedBox(height: 12),
                              _VintageSpecRow(
                                icon: CupertinoIcons.person,
                                label: 'Vendedor',
                                value: product.sellerName!,
                              ),
                            ],
                            const SizedBox(height: 16),

                            // Botón discreto para abrir modal de guía de medidas
                            IosPressable(
                              onTap: () => _showSizeGuideModal(
                                context,
                                selectedVariant?.size ?? 'Única',
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSoft,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border, width: 0.6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(CupertinoIcons.resize, size: 16, color: AppColors.dark),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Talla etiqueta vs. medidas reales',
                                        style: AppTypography.labelLarge,
                                      ),
                                    ),
                                    const Icon(CupertinoIcons.chevron_right, size: 14, color: AppColors.gray),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Selector de variantes (Talla y Color)
                            if (product.variants.isNotEmpty) ...[
                              Text('Talla y Color', style: AppTypography.titleSmall),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: product.variants.map((v) {
                                  final isSelected = selectedVariant?.id == v.id;
                                  return IosPressable(
                                    onTap: () => setState(() => selectedVariant = v),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.dark : AppColors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected ? AppColors.dark : AppColors.border,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${v.size} · ${v.color}',
                                            style: AppTypography.labelLarge.copyWith(
                                              color: isSelected ? AppColors.white : AppColors.dark,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            v.stock <= 0 ? 'Agotado' : '${v.stock} disp.',
                                            style: AppTypography.labelSmall.copyWith(
                                              color: v.stock <= 0
                                                  ? AppColors.error
                                                  : (isSelected ? AppColors.surfaceSoft : AppColors.gray),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Descripción
                            Text('Descripción', style: AppTypography.titleSmall),
                            const SizedBox(height: 8),
                            Text(
                              product.description.isEmpty
                                  ? 'Prenda vintage seleccionada cuidadosamente.'
                                  : product.description,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.gray,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),

                            // Garantías editoriales discretas
                            Row(
                              children: [
                                const Icon(CupertinoIcons.checkmark_shield, size: 16, color: AppColors.dark),
                                const SizedBox(width: 8),
                                Text('Compra protegida', style: AppTypography.bodySmall),
                                const SizedBox(width: 20),
                                const Icon(CupertinoIcons.arrow_2_circlepath, size: 16, color: AppColors.dark),
                                const SizedBox(width: 8),
                                Text('Moda circular verificada', style: AppTypography.bodySmall),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Barra inferior fija estilo iOS (borde sutil 0.5px, sin sombras pesadas)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppColors.light,
                  border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Selector de cantidad minimalista
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(CupertinoIcons.minus, size: 16),
                              color: AppColors.dark,
                              onPressed: (remainingStock > 0 && quantity > 1)
                                  ? () => setState(() => quantity--)
                                  : null,
                            ),
                            Text(
                              '${remainingStock > 0 ? quantity : 0}',
                              style: AppTypography.titleMedium,
                            ),
                            IconButton(
                              icon: const Icon(CupertinoIcons.plus, size: 16),
                              color: AppColors.dark,
                              onPressed: (remainingStock > 0 && quantity < remainingStock)
                                  ? () => setState(() => quantity++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // CTA principal en negro tinta
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (selectedVariant == null || remainingStock <= 0)
                              ? null
                              : () async {
                                  final error = await ref
                                      .read(cartProvider.notifier)
                                      .addProduct(selectedVariant!.id, quantity);
                                  if (!context.mounted) return;
                                  if (error != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(error),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${quantity}x ${product.name} agregado a tu bolsa'),
                                        backgroundColor: AppColors.dark,
                                      ),
                                    );
                                    setState(() => quantity = 1);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.dark,
                            disabledBackgroundColor: AppColors.border,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            variantStock <= 0
                                ? 'Agotado'
                                : (remainingStock <= 0
                                    ? 'En carrito (Máx $variantStock)'
                                    : 'Añadir a la bolsa'),
                            style: AppTypography.button,
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
}

class _VintageSpecRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _VintageSpecRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.gray),
        const SizedBox(width: 10),
        Text('$label:', style: AppTypography.bodySmall),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  final String label;
  final String value;

  const _MeasurementRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall),
        Text(value, style: AppTypography.titleSmall),
      ],
    );
  }
}
