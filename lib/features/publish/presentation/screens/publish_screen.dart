import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_typography.dart';
import '../../../../shared/widgets/ios_pressable.dart';
import '../../../catalog/data/models/product.dart';
import '../../data/repositories/publish_repository.dart';
import '../providers/publish_provider.dart';

/// Valida y sanitiza el precio para publicaciones C2C de prendas vintage.
/// Sanea símbolos '$', espacios y comas decimales antes de evaluar el valor numérico.
String? validateAndSanitizePrice(String? val) {
  if (val == null || val.trim().isEmpty) {
    return 'Requerido';
  }
  final cleaned = val
      .replaceAll('\$', '')
      .replaceAll(',', '.')
      .trim();
  final parsed = double.tryParse(cleaned);
  if (parsed == null || parsed <= 0) {
    return 'El precio debe ser mayor a 0';
  }
  return null;
}

class PublishScreen extends ConsumerStatefulWidget {
  const PublishScreen({super.key});

  @override
  ConsumerState<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends ConsumerState<PublishScreen> {
  final _formKey = GlobalKey<FormState>();
  XFile? _imageFile;
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final _customBrandController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  static const int _otherOptionId = -1;
  int _selectedBrandId = 1;
  int _selectedCategoryId = 1;
  String _selectedCondition = 'Excelente';
  final List<String> _conditions = ['Nuevo con etiqueta', 'Excelente', 'Buen estado', 'Usado'];

  @override
  void initState() {
    super.initState();
    _retrieveLostData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _customBrandController.dispose();
    _customCategoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Recupera fotos si Android destruyó la actividad en segundo plano
  Future<void> _retrieveLostData() async {
    if (kIsWeb) return;
    try {
      final picker = ImagePicker();
      final LostDataResponse response = await picker.retrieveLostData();
      if (response.isEmpty) return;

      if (response.file != null) {
        setState(() {
          _imageFile = response.file;
        });
      } else if (response.exception != null) {
        debugPrint('Error recuperando imagen perdida: ${response.exception}');
      }
    } catch (e) {
      debugPrint('Excepción en retrieveLostData: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, toma una foto de la prenda')),
        );
        return;
      }

      // Sanitizar precio de forma segura (soporta comas, símbolo $, espacios)
      final rawPrice = _priceController.text.replaceAll('\$', '').replaceAll(',', '.').trim();
      final parsedPrice = double.tryParse(rawPrice);

      if (parsedPrice == null || parsedPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El precio debe ser mayor a 0')),
        );
        return;
      }

      final parsedStock = int.tryParse(_stockController.text.trim()) ?? 1;

      ref.read(publishProvider.notifier).publish(
        image: _imageFile!,
        title: _titleController.text.trim(),
        price: parsedPrice,
        stock: parsedStock > 0 ? parsedStock : 1,
        brandId: _selectedBrandId,
        categoryId: _selectedCategoryId,
        customBrand: _selectedBrandId == _otherOptionId ? _customBrandController.text.trim() : null,
        customCategory:
            _selectedCategoryId == _otherOptionId ? _customCategoryController.text.trim() : null,
        condition: _selectedCondition,
        description: _descriptionController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PublishState>(publishProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al publicar: ${next.error}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      if (next.publishedProduct != null && previous?.publishedProduct != next.publishedProduct) {
        final product = next.publishedProduct!;

        // Limpiar formulario y foto
        _formKey.currentState?.reset();
        _titleController.clear();
        _priceController.clear();
        _stockController.text = '1';
        _customBrandController.clear();
        _customCategoryController.clear();
        _descriptionController.clear();
        setState(() {
          _imageFile = null;
        });

        // Mostrar alerta de éxito con opciones para ver el producto o ir al catálogo
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '¡Prenda Publicada!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Text(
              'Tu prenda "${product.name}" ya está publicada y lista en VintageVibe.',
              style: AppTypography.bodyMedium,
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.go('/home');
                },
                child: const Text('Ir al Catálogo', style: TextStyle(color: AppColors.gray)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.push('/product/${product.id}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Ver Prenda'),
              ),
            ],
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('Publicar Prenda'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.grayLight),
                  ),
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt, size: 48, color: AppColors.primary),
                            const SizedBox(height: 8),
                            Text('Tomar o seleccionar foto', style: AppTypography.bodyLarge.copyWith(color: AppColors.primary)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: FutureBuilder<Uint8List>(
                            future: _imageFile!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 200,
                                );
                              }
                              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                            },
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Fields
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título de la prenda',
                  hintText: 'Ej. Chamarra Levis Vintage',
                  errorMaxLines: 2,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio (\$)',
                        hintText: '0.00',
                        errorMaxLines: 2,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: validateAndSanitizePrice,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock (pzas)',
                        hintText: '1',
                        errorMaxLines: 2,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (val) {
                        final parsed = int.tryParse(val?.trim() ?? '');
                        if (parsed == null || parsed < 1) {
                          return 'Mín. 1';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Selector de Marca desde la BD + opción "Otra marca"
              Consumer(
                builder: (context, ref, _) {
                  final brandsAsync = ref.watch(brandsProvider);
                  final dbBrands = brandsAsync.asData?.value ??
                      const [
                        CatalogOption(id: 1, name: "Levi's"),
                        CatalogOption(id: 2, name: 'Nike'),
                        CatalogOption(id: 3, name: 'Adidas'),
                      ];
                  final items = [
                    ...dbBrands,
                    const CatalogOption(id: _otherOptionId, name: 'Otra marca'),
                  ];
                  final effectiveValue = items.any((b) => b.id == _selectedBrandId)
                      ? _selectedBrandId
                      : items.first.id;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Marca', style: AppTypography.bodySmall.copyWith(color: AppColors.gray)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: effectiveValue,
                            isExpanded: true,
                            icon: const Icon(CupertinoIcons.chevron_down, size: 16, color: AppColors.gray),
                            items: items.map((brand) {
                              return DropdownMenuItem<int>(
                                value: brand.id,
                                child: Text(brand.name, style: AppTypography.bodyMedium),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedBrandId = val);
                              }
                            },
                          ),
                        ),
                      ),
                      if (_selectedBrandId == _otherOptionId) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _customBrandController,
                          decoration: const InputDecoration(
                            labelText: 'Especifica la marca',
                            hintText: 'Ej. Carhartt, Ralph Lauren, Wrangler',
                            errorMaxLines: 2,
                          ),
                          validator: (val) =>
                              val == null || val.trim().isEmpty ? 'Ingresa el nombre de la marca' : null,
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Selector de Categoría desde la BD + opción "Otra categoría"
              Consumer(
                builder: (context, ref, _) {
                  final categoriesAsync = ref.watch(categoriesProvider);
                  final dbCategories = categoriesAsync.asData?.value ??
                      const [
                        CatalogOption(id: 1, name: 'Ropa Exterior'),
                        CatalogOption(id: 2, name: 'Camisetas'),
                        CatalogOption(id: 3, name: 'Pantalones'),
                      ];
                  final items = [
                    ...dbCategories,
                    const CatalogOption(id: _otherOptionId, name: 'Otra categoría'),
                  ];
                  final effectiveCat = items.any((c) => c.id == _selectedCategoryId)
                      ? _selectedCategoryId
                      : items.first.id;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Categoría', style: AppTypography.bodySmall.copyWith(color: AppColors.gray)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: effectiveCat,
                            isExpanded: true,
                            icon: const Icon(CupertinoIcons.chevron_down, size: 16, color: AppColors.gray),
                            items: items.map((cat) {
                              return DropdownMenuItem<int>(
                                value: cat.id,
                                child: Text(cat.name, style: AppTypography.bodyMedium),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCategoryId = val);
                              }
                            },
                          ),
                        ),
                      ),
                      if (_selectedCategoryId == _otherOptionId) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _customCategoryController,
                          decoration: const InputDecoration(
                            labelText: 'Especifica la categoría',
                            hintText: 'Ej. Accesorios, Calzado, Sudaderas',
                            errorMaxLines: 2,
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Ingresa el nombre de la categoría'
                              : null,
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              Text('Estado de la prenda', style: AppTypography.bodySmall.copyWith(color: AppColors.gray)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grayLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCondition,
                    isExpanded: true,
                    items: _conditions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: AppTypography.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCondition = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (Opcional)',
                  hintText: 'Describe los detalles, año aproximado, etc.',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              Consumer(
                builder: (context, ref, child) {
                  final publishState = ref.watch(publishProvider);
                  return ElevatedButton(
                    onPressed: publishState.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: publishState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Publicar',
                            style: AppTypography.bodyLarge.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
                          ),
                  );
                },
              ),
              const SizedBox(height: 40), // Bottom padding for nav bar
            ],
          ),
        ),
      ),
    );
  }
}

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  void _openEditSheet(BuildContext context, WidgetRef ref, Product listing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.light,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditListingSheet(listing: listing),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Product listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: Text('¿Seguro que deseas eliminar "${listing.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await ref.read(publishProvider.notifier).deleteListing(listing.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Publicación eliminada'),
        backgroundColor: error != null ? AppColors.error : AppColors.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(myListingsProvider);

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('Mis Publicaciones'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, size: 20, color: AppColors.dark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.tag, size: 40, color: AppColors.gray),
                    const SizedBox(height: 12),
                    Text('No tienes prendas publicadas', style: AppTypography.headlineSmall),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: listings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final listing = listings[index];
              final stock = listing.variants.isNotEmpty ? listing.variants.first.stock : 0;

              return IosPressable(
                onTap: () => _openEditSheet(context, ref, listing),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 60,
                          height: 76,
                          color: AppColors.surfaceSoft,
                          child: listing.images.isNotEmpty
                              ? Image.network(
                                  listing.images.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    CupertinoIcons.photo,
                                    color: AppColors.gray,
                                    size: 22,
                                  ),
                                )
                              : const Icon(CupertinoIcons.photo, color: AppColors.gray, size: 22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing.name,
                              style: AppTypography.titleSmall.copyWith(fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${listing.price.toStringAsFixed(2)} · Stock: $stock',
                              style: AppTypography.bodySmall.copyWith(
                                color: stock <= 0 ? AppColors.error : AppColors.gray,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${listing.brandName ?? 'Vintage'} · ${listing.categoryName ?? 'General'}',
                              style: AppTypography.labelSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.pencil, size: 18, color: AppColors.dark),
                        onPressed: () => _openEditSheet(context, ref, listing),
                        tooltip: 'Editar prenda',
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.trash, size: 18, color: AppColors.error),
                        onPressed: () => _confirmDelete(context, ref, listing),
                        tooltip: 'Eliminar prenda',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CupertinoActivityIndicator(radius: 12, color: AppColors.dark),
        ),
        error: (e, st) => Center(child: Text('Error al cargar publicaciones: $e')),
      ),
    );
  }
}

class _EditListingSheet extends ConsumerStatefulWidget {
  final Product listing;
  const _EditListingSheet({required this.listing});

  @override
  ConsumerState<_EditListingSheet> createState() => _EditListingSheetState();
}

class _EditListingSheetState extends ConsumerState<_EditListingSheet> {
  static const int _otherOptionId = -1;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _sizeCtrl;
  late TextEditingController _descCtrl;
  final _customBrandCtrl = TextEditingController();
  final _customCategoryCtrl = TextEditingController();

  int _selectedBrandId = 1;
  int _selectedCategoryId = 1;
  String _selectedCondition = 'Excelente';
  bool _isSaving = false;

  final List<String> _conditions = ['Nuevo con etiqueta', 'Excelente', 'Buen estado', 'Usado'];

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    final firstVariant = l.variants.isNotEmpty ? l.variants.first : null;
    _titleCtrl = TextEditingController(text: l.name);
    _priceCtrl = TextEditingController(text: l.price.toStringAsFixed(2));
    _stockCtrl = TextEditingController(text: '${firstVariant?.stock ?? 1}');
    _sizeCtrl = TextEditingController(text: firstVariant?.size ?? 'U');
    _descCtrl = TextEditingController(text: l.description);
    if (l.conditionName != null && _conditions.contains(l.conditionName)) {
      _selectedCondition = l.conditionName!;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _sizeCtrl.dispose();
    _descCtrl.dispose();
    _customBrandCtrl.dispose();
    _customCategoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final rawPrice = _priceCtrl.text.replaceAll('\$', '').replaceAll(',', '.').trim();
    final parsedPrice = double.tryParse(rawPrice) ?? widget.listing.price;
    final parsedStock = int.tryParse(_stockCtrl.text.trim()) ?? 0;

    final error = await ref.read(publishProvider.notifier).updateListing(
          existing: widget.listing,
          title: _titleCtrl.text.trim(),
          price: parsedPrice,
          stock: parsedStock,
          size: _sizeCtrl.text.trim(),
          brandId: _selectedBrandId,
          categoryId: _selectedCategoryId,
          customBrand: _selectedBrandId == _otherOptionId ? _customBrandCtrl.text.trim() : null,
          customCategory:
              _selectedCategoryId == _otherOptionId ? _customCategoryCtrl.text.trim() : null,
          condition: _selectedCondition,
          description: _descCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    } else {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación actualizada correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brands = [
      ...(ref.watch(brandsProvider).asData?.value ??
          const [
            CatalogOption(id: 1, name: "Levi's"),
            CatalogOption(id: 2, name: 'Nike'),
            CatalogOption(id: 3, name: 'Adidas'),
          ]),
      const CatalogOption(id: _otherOptionId, name: 'Otra marca'),
    ];
    final categories = [
      ...(ref.watch(categoriesProvider).asData?.value ??
          const [
            CatalogOption(id: 1, name: 'Ropa Exterior'),
            CatalogOption(id: 2, name: 'Camisetas'),
            CatalogOption(id: 3, name: 'Pantalones'),
          ]),
      const CatalogOption(id: _otherOptionId, name: 'Otra categoría'),
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Editar publicación', style: AppTypography.headlineSmall),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Título de la prenda'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(labelText: 'Precio (\$)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: validateAndSanitizePrice,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _stockCtrl,
                      decoration: const InputDecoration(labelText: 'Stock'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => (int.tryParse(v ?? '') ?? -1) < 0 ? 'Inválido' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _sizeCtrl,
                      decoration: const InputDecoration(labelText: 'Talla'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: brands.any((b) => b.id == _selectedBrandId) ? _selectedBrandId : brands.first.id,
                decoration: const InputDecoration(labelText: 'Marca'),
                items: brands
                    .map((b) => DropdownMenuItem<int>(value: b.id, child: Text(b.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedBrandId = v ?? 1),
              ),
              if (_selectedBrandId == _otherOptionId) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _customBrandCtrl,
                  decoration: const InputDecoration(labelText: 'Especifica la marca'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: categories.any((c) => c.id == _selectedCategoryId)
                    ? _selectedCategoryId
                    : categories.first.id,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: categories
                    .map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v ?? 1),
              ),
              if (_selectedCategoryId == _otherOptionId) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _customCategoryCtrl,
                  decoration: const InputDecoration(labelText: 'Especifica la categoría'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: _conditions
                    .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCondition = v ?? 'Excelente'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const CupertinoActivityIndicator(radius: 9, color: AppColors.white)
                    : const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
