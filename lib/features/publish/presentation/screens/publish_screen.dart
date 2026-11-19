import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_typography.dart';
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
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  
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
    _brandController.dispose();
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

      ref.read(publishProvider.notifier).publish(
        image: _imageFile!,
        title: _titleController.text.trim(),
        price: parsedPrice,
        brand: _brandController.text.trim(),
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
        _brandController.clear();
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(
                        labelText: 'Marca',
                        hintText: 'Ej. Nike',
                        errorMaxLines: 2,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(myListingsProvider);
    
    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(title: const Text('Mis Publicaciones')),
      body: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return const Center(child: Text('No tienes prendas publicadas'));
          }
          return ListView.builder(
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              return ListTile(
                leading: listing.images.isNotEmpty 
                  ? Image.network(listing.images.first, width: 50, height: 50, fit: BoxFit.cover)
                  : const Icon(Icons.image),
                title: Text(listing.name),
                subtitle: Text('\$${listing.price}'),
                trailing: const Icon(Icons.chevron_right),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
