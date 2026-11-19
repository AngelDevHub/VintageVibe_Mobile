import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_typography.dart';
import '../../../../shared/widgets/ios_pressable.dart';
import '../../data/models/product.dart';
import '../../../publish/presentation/providers/publish_provider.dart';
import '../providers/catalog_provider.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedBrand;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _filterProducts(List<Product> products) {
    var result = products;

    if (_selectedCategory != null) {
      result = result.where((p) =>
        (p.categoryName ?? '').trim().toLowerCase() == _selectedCategory!.trim().toLowerCase()
      ).toList();
    }

    if (_selectedBrand != null) {
      result = result.where((p) =>
        (p.brandName ?? '').trim().toLowerCase() == _selectedBrand!.trim().toLowerCase()
      ).toList();
    }

    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((p) {
        final nameMatch = p.name.toLowerCase().contains(q);
        final brandMatch = (p.brandName ?? '').toLowerCase().contains(q);
        final categoryMatch = (p.categoryName ?? '').toLowerCase().contains(q);
        final conditionMatch = (p.conditionName ?? '').toLowerCase().contains(q);
        final sizeMatch = p.variants.any((v) => v.size.toLowerCase().contains(q));
        return nameMatch || brandMatch || categoryMatch || conditionMatch || sizeMatch;
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final screenWidth = mediaQuery.size.width;

    final int crossAxisCount = screenWidth > 900
        ? 4
        : (isLandscape || screenWidth > 600 ? 3 : 2);

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('Explorar'),
        centerTitle: false,
        backgroundColor: AppColors.light,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh, size: 20, color: AppColors.dark),
            onPressed: () => ref.invalidate(productsProvider),
            tooltip: 'Actualizar catálogo',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Buscador editorial estilo iOS
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.6),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: AppTypography.bodyMedium,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar prendas, marcas o tallas...',
                  hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.gray),
                  prefixIcon: const Icon(CupertinoIcons.search, size: 16, color: AppColors.gray),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            CupertinoIcons.xmark_circle_fill,
                            size: 16,
                            color: AppColors.gray,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // Carrusel de Categorías estilo Shein
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
            child: Row(
              children: [
                Text(
                  'Categorías',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.gray,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                if (_selectedCategory != null || _selectedBrand != null || _searchQuery.isNotEmpty)
                  IosPressable(
                    onTap: () {
                      setState(() {
                        _selectedCategory = null;
                        _selectedBrand = null;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                    child: Text(
                      'Limpiar filtros',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildCategoryCarousel(ref, productsAsync.value ?? const []),
          const SizedBox(height: 6),

          // Carrusel de Marcas estilo Shein
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
            child: Row(
              children: [
                Text(
                  'Marcas',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.gray,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _buildBrandCarousel(ref, productsAsync.value ?? const []),
          const SizedBox(height: 8),

          // Lista / Grid de productos
          Expanded(
            child: RefreshIndicator(
              color: AppColors.dark,
              backgroundColor: AppColors.white,
              onRefresh: () async {
                ref.invalidate(productsProvider);
                await ref.read(productsProvider.future);
              },
              child: productsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        const Icon(CupertinoIcons.tag, size: 36, color: AppColors.gray),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'No hay prendas disponibles',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.gray),
                          ),
                        ),
                      ],
                    );
                  }

                  final filtered = _filterProducts(products);
                  if (filtered.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 100),
                        const Icon(CupertinoIcons.search, size: 36, color: AppColors.gray),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Sin resultados para "$_searchQuery"',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.gray),
                          ),
                        ),
                      ],
                    );
                  }

                  return GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 92),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.54,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 24,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _EditorialProductCard(product: filtered[index]);
                    },
                  );
                },
                loading: () => const Center(
                  child: CupertinoActivityIndicator(radius: 12, color: AppColors.dark),
                ),
                error: (error, stack) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 120),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const Icon(CupertinoIcons.wifi_slash, size: 36, color: AppColors.gray),
                            const SizedBox(height: 16),
                            Text(
                              'No se pudieron cargar las prendas',
                              style: AppTypography.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Verifica tu conexión a internet o el estado del servidor e inténtalo de nuevo.',
                              style: AppTypography.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => ref.invalidate(productsProvider),
                              icon: const Icon(CupertinoIcons.refresh, size: 16),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCarousel(WidgetRef ref, List<Product> products) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final categorySet = <String>{};

    categoriesAsync.whenData((list) {
      for (final item in list) {
        if (item.name.trim().isNotEmpty) categorySet.add(item.name.trim());
      }
    });

    for (final p in products) {
      if (p.categoryName != null && p.categoryName!.trim().isNotEmpty) {
        categorySet.add(p.categoryName!.trim());
      }
    }

    final categories = ['Todas', ...categorySet];

    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = (index == 0 && _selectedCategory == null) ||
              (_selectedCategory?.toLowerCase() == cat.toLowerCase());

          return _buildFilterChip(
            label: cat,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (index == 0) {
                  _selectedCategory = null;
                } else {
                  _selectedCategory = (_selectedCategory == cat) ? null : cat;
                }
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildBrandCarousel(WidgetRef ref, List<Product> products) {
    final brandsAsync = ref.watch(brandsProvider);
    final brandSet = <String>{};

    brandsAsync.whenData((list) {
      for (final item in list) {
        if (item.name.trim().isNotEmpty) brandSet.add(item.name.trim());
      }
    });

    for (final p in products) {
      if (p.brandName != null && p.brandName!.trim().isNotEmpty) {
        brandSet.add(p.brandName!.trim());
      }
    }

    final brands = ['Todas', ...brandSet];

    return SizedBox(
      height: 30,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: brands.length,
        itemBuilder: (context, index) {
          final brand = brands[index];
          final isSelected = (index == 0 && _selectedBrand == null) ||
              (_selectedBrand?.toLowerCase() == brand.toLowerCase());

          return _buildFilterChip(
            label: brand,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (index == 0) {
                  _selectedBrand = null;
                } else {
                  _selectedBrand = (_selectedBrand == brand) ? null : brand;
                }
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return IosPressable(
      onTap: onTap,
      pressedScale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.dark : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.dark : AppColors.border,
            width: 0.7,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isSelected ? AppColors.white : AppColors.dark,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorialProductCard extends StatelessWidget {
  final Product product;

  const _EditorialProductCard({required this.product});

  String _buildMetadata() {
    final parts = <String>[];
    if (product.variants.isNotEmpty) {
      final size = product.variants.first.size.trim();
      if (size.isNotEmpty && size != 'N/A') {
        parts.add('Talla $size');
      }
    }
    if (product.brandName != null && product.brandName!.trim().isNotEmpty) {
      parts.add(product.brandName!.trim());
    } else if (product.conditionName != null && product.conditionName!.trim().isNotEmpty) {
      parts.add(product.conditionName!.trim());
    }
    return parts.isEmpty ? 'Vintage seleccionado' : parts.join(' · ');
  }

  String? _availabilityLabel() {
    if (product.variants.isEmpty) return null;
    final totalStock = product.variants.fold<int>(0, (sum, v) => sum + v.stock);
    if (totalStock <= 0) return 'Agotado';
    if (totalStock == 1) return 'Pieza única';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = product.images.isNotEmpty;
    final availability = _availabilityLabel();

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
          Text(
            product.name,
            style: AppTypography.titleSmall.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _buildMetadata(),
            style: AppTypography.labelMedium.copyWith(
              fontSize: 12,
              color: AppColors.gray,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: AppTypography.priceSmall,
              ),
              if (availability != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    availability,
                    style: AppTypography.labelSmall.copyWith(
                      color: availability == 'Agotado' ? AppColors.error : AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
