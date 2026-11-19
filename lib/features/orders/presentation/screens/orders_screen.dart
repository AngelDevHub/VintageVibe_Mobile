import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_typography.dart';
import '../providers/order_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pedido #${order.id}', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                        _buildStatusBadge(order.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Fecha: ${order.orderDate.split('T').first}', style: AppTypography.bodySmall.copyWith(color: AppColors.gray)),
                    const SizedBox(height: 8),
                    Text('Total: MXN ${order.totalAmount.toStringAsFixed(2)}', style: AppTypography.bodyMedium.copyWith(color: AppColors.dark, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, st) => Center(child: Text('Error al cargar pedidos: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status.toUpperCase()) {
      case 'PENDING':
        color = Colors.orange;
        text = 'Pendiente';
        break;
      case 'PAID':
      case 'COMPLETED':
        color = Colors.green;
        text = 'Pagado';
        break;
      case 'SHIPPED':
        color = Colors.blue;
        text = 'Enviado';
        break;
      case 'CANCELLED':
        color = Colors.red;
        text = 'Cancelado';
        break;
      default:
        color = AppColors.gray;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: AppTypography.bodySmall.copyWith(color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.grayLight),
          const SizedBox(height: 24),
          Text('No tienes pedidos aún', style: AppTypography.displayMedium.copyWith(color: AppColors.dark)),
        ],
      ),
    );
  }
}
