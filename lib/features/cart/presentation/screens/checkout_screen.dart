import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_typography.dart';
import '../providers/cart_provider.dart';
import '../providers/checkout_provider.dart';
import '../../../profile/presentation/providers/address_provider.dart';
import '../../../profile/data/repositories/address_repository.dart';
import '../../../profile/data/models/address_model.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  AddressModel? _selectedAddress;
  String _selectedPaymentMethod = 'CREDIT_CARD';
  final _addressFormKey = GlobalKey<FormState>();
  
  // Temporary form controllers if no address exists
  final _fullNameCtrl = TextEditingController();
  final _address1Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _address1Ctrl.dispose();
    _cityCtrl.dispose();
    _postalCtrl.dispose();
    _countryCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final cartTotal = cartAsync.value?.total ?? 0.0;
    final addressesAsync = ref.watch(addressesProvider);
    final checkoutState = ref.watch(checkoutProvider);

    // Listen for checkout success
    ref.listen<CheckoutState>(checkoutProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error!)));
      } else if (next.successOrder != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('¡Pedido Confirmado!'),
            content: Text('Tu número de pedido es #${next.successOrder!.id}'),
            actions: [
              TextButton(
                onPressed: () {
                  context.go('/home');
                },
                child: const Text('Continuar Comprando'),
              ),
              TextButton(
                onPressed: () {
                  context.go('/orders');
                },
                child: const Text('Ver Mis Pedidos'),
              )
            ],
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: checkoutState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dirección de Envío', style: AppTypography.displaySmall.copyWith(color: AppColors.dark)),
                  const SizedBox(height: 16),
                  addressesAsync.when(
                    data: (addresses) {
                      if (addresses.isEmpty) {
                        return _buildNewAddressForm();
                      }
                      _selectedAddress ??= addresses.first;
                      return _buildAddressSelector(addresses);
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Error al cargar direcciones', style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(height: 32),
                  Text('Método de Pago', style: AppTypography.displaySmall.copyWith(color: AppColors.dark)),
                  const SizedBox(height: 16),
                  _buildPaymentSelector(),
                  const SizedBox(height: 32),
                  
                  // Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total a pagar:', style: AppTypography.bodyLarge),
                            Text('MXN ${cartTotal.toStringAsFixed(2)}', style: AppTypography.displaySmall),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _onConfirmOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.dark,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Confirmar Pedido', style: AppTypography.bodyLarge.copyWith(color: AppColors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAddressSelector(List<AddressModel> addresses) {
    return Column(
      children: addresses.map((addr) {
        final isSelected = _selectedAddress?.id == addr.id;
        return GestureDetector(
          onTap: () => setState(() => _selectedAddress = addr),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 2),
            ),
            child: Row(
              children: [
                Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? AppColors.primary : AppColors.gray),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(addr.fullName, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                      Text('${addr.addressLine1}, ${addr.city}, ${addr.postalCode}', style: AppTypography.bodySmall.copyWith(color: AppColors.gray)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNewAddressForm() {
    if (_countryCtrl.text.isEmpty) {
      _countryCtrl.text = 'México';
    }

    return Form(
      key: _addressFormKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text('Agrega una dirección para continuar', style: AppTypography.bodyMedium.copyWith(color: AppColors.gray)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fullNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo',
                hintText: 'Ej. Ángel Gómez',
                errorMaxLines: 2,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'El nombre completo es obligatorio';
                if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(v.trim())) {
                  return 'El nombre solo debe contener letras';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _address1Ctrl,
              decoration: const InputDecoration(
                labelText: 'Calle y Número',
                hintText: 'Ej. Av. Hidalgo #123 o Calle 5 No. 45',
                errorMaxLines: 2,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'La dirección es obligatoria' : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ciudad',
                      hintText: 'Ej. Guadalajara',
                      errorMaxLines: 2,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Ciudad obligatoria' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _postalCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(5),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'C.P. (5 dígitos)',
                      hintText: '76890',
                      errorMaxLines: 2,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'C.P. obligatorio';
                      if (v.trim().length != 5) return 'Debe tener 5 dígitos';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _countryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'País',
                      errorMaxLines: 2,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'País obligatorio' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Teléfono (10 dígitos)',
                      hintText: '3312345678',
                      errorMaxLines: 2,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Teléfono obligatorio';
                      if (v.trim().length != 10) return 'Debe tener exactamente 10 dígitos';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSelector() {
    final methods = [
      {
        'id': 'CREDIT_CARD',
        'name': 'Tarjeta de Crédito',
        'subtitle': 'Visa, Mastercard, American Express',
        'icon': Icons.credit_card_rounded,
      },
      {
        'id': 'DEBIT_CARD',
        'name': 'Tarjeta de Débito',
        'subtitle': 'Pago directo con fondos bancarios',
        'icon': Icons.credit_card_outlined,
      },
      {
        'id': 'PAYPAL',
        'name': 'PayPal',
        'subtitle': 'Pago rápido y seguro con tu cuenta PayPal',
        'icon': Icons.account_balance_wallet_outlined,
      },
      {
        'id': 'BANK_TRANSFER',
        'name': 'Transferencia Bancaria (SPEI)',
        'subtitle': 'Transferencia interbancaria electrónica',
        'icon': Icons.account_balance_outlined,
      },
      {
        'id': 'CASH_ON_DELIVERY',
        'name': 'Pago en Efectivo (Contra Entrega / OXXO)',
        'subtitle': 'Paga en tienda de conveniencia o al recibir',
        'icon': Icons.payments_outlined,
      },
    ];

    return Column(
      children: methods.map((m) {
        final isSelected = _selectedPaymentMethod == m['id'];
        return GestureDetector(
          onTap: () => setState(() => _selectedPaymentMethod = m['id'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 2),
            ),
            child: Row(
              children: [
                Icon(m['icon'] as IconData, color: isSelected ? AppColors.primary : AppColors.dark, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m['name'] as String, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(m['subtitle'] as String, style: AppTypography.bodySmall.copyWith(color: AppColors.gray, fontSize: 11)),
                    ],
                  ),
                ),
                if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _onConfirmOrder() async {
    final addressesAsync = ref.read(addressesProvider);
    if (addressesAsync.value == null) return;
    
    int? finalAddressId;

    if (addressesAsync.value!.isEmpty) {
      if (!_addressFormKey.currentState!.validate()) return;
      
      // We would normally save the address first.
      // For this implementation, we assume we use a Provider to save it.
      // Actually, let's create it via the AddressRepository.
      final newAddress = AddressModel(
        fullName: _fullNameCtrl.text,
        addressLine1: _address1Ctrl.text,
        city: _cityCtrl.text,
        postalCode: _postalCtrl.text,
        country: _countryCtrl.text,
        phoneNumber: _phoneCtrl.text,
      );
      
      try {
        final saved = await ref.read(addressRepositoryProvider).createAddress(newAddress);
        if (!mounted) return;
        finalAddressId = saved.id;
      } catch (e) {
        if (!mounted) return;
        String errorMsg = 'Error al guardar dirección';
        if (e is DioException && e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map) {
            errorMsg = data.values.join('\n');
          } else if (data is String) {
            errorMsg = data;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    } else {
      if (_selectedAddress == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona una dirección')));
        return;
      }
      finalAddressId = _selectedAddress!.id;
    }

    if (finalAddressId != null) {
      ref.read(checkoutProvider.notifier).submitOrder(
        addressId: finalAddressId,
        paymentMethod: _selectedPaymentMethod,
      );
    }
  }
}
