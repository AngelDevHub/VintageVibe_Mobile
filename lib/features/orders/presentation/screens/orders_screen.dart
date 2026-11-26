import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_typography.dart';
import '../../data/models/order_model.dart';
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
          return RefreshIndicator(
            color: AppColors.dark,
            onRefresh: () async => ref.invalidate(ordersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final itemCount = order.items.fold<int>(0, (sum, i) => sum + i.quantity);

                return GestureDetector(
                  onTap: () => _showOrderDetailModal(context, order),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 0.6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                order.orderNumber.isNotEmpty
                                    ? 'Pedido ${order.orderNumber}'
                                    : 'Pedido #${order.id}',
                                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(order.status),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(CupertinoIcons.calendar, size: 14, color: AppColors.gray),
                            const SizedBox(width: 6),
                            Text(
                              order.formattedDate,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.gray),
                            ),
                            if (itemCount > 0) ...[
                              const SizedBox(width: 12),
                              Text(
                                '· $itemCount ${itemCount == 1 ? "prenda" : "prendas"}',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.gray),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total: MXN ${order.totalAmount.toStringAsFixed(2)}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.dark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Ver detalle',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: AppColors.dark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(CupertinoIcons.chevron_right, size: 14, color: AppColors.dark),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error al cargar pedidos: $e', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }

  void _showOrderDetailModal(BuildContext context, OrderModel order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.light,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header del pedido
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.orderNumber.isNotEmpty
                                  ? 'Pedido ${order.orderNumber}'
                                  : 'Pedido #${order.id}',
                              style: AppTypography.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(CupertinoIcons.calendar, size: 14, color: AppColors.gray),
                                const SizedBox(width: 6),
                                Text(
                                  order.formattedDate,
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.gray),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(order.status),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Artículos del pedido
                  Text('Artículos (${order.items.length})', style: AppTypography.titleSmall),
                  const SizedBox(height: 10),
                  if (order.items.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 0.6),
                      ),
                      child: Text(
                        'Sin desglose de artículos disponible.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.gray),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 0.6),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: order.items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, indent: 14, endIndent: 14),
                        itemBuilder: (context, idx) {
                          final item = order.items[idx];
                          return Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceSoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(CupertinoIcons.bag, size: 18, color: AppColors.dark),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Talla ${item.size} · ${item.color} · Cant. ${item.quantity}',
                                        style: AppTypography.bodySmall.copyWith(color: AppColors.gray),
                                      ),
                                      if (item.variantSku.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'SKU: ${item.variantSku}',
                                          style: AppTypography.labelSmall.copyWith(color: AppColors.gray),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'MXN ${item.totalPrice.toStringAsFixed(2)}',
                                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    if (item.quantity > 1)
                                      Text(
                                        '${item.quantity} × ${item.unitPrice.toStringAsFixed(0)}',
                                        style: AppTypography.labelSmall.copyWith(color: AppColors.gray),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Envío y método de pago
                  Text('Envío y Pago', style: AppTypography.titleSmall),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 0.6),
                    ),
                    child: Column(
                      children: [
                        if (order.shippingFullName != null && order.shippingFullName!.isNotEmpty) ...[
                          _buildInfoRow(
                            icon: CupertinoIcons.person,
                            label: 'Destinatario',
                            value: order.shippingFullName!,
                          ),
                          const SizedBox(height: 10),
                        ],
                        if ((order.shippingCity != null && order.shippingCity!.isNotEmpty) ||
                            (order.shippingCountry != null && order.shippingCountry!.isNotEmpty)) ...[
                          _buildInfoRow(
                            icon: CupertinoIcons.location_solid,
                            label: 'Destino',
                            value: [order.shippingCity, order.shippingCountry]
                                .where((s) => s != null && s.isNotEmpty)
                                .join(', '),
                          ),
                          const SizedBox(height: 10),
                        ],
                        _buildInfoRow(
                          icon: CupertinoIcons.creditcard,
                          label: 'Método de pago',
                          value: order.formattedPaymentMethod,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Resumen de totales
                  Text('Resumen del Pago', style: AppTypography.titleSmall),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 0.6),
                    ),
                    child: Column(
                      children: [
                        _buildAmountRow('Subtotal', 'MXN ${order.subtotal.toStringAsFixed(2)}'),
                        if (order.discountAmount > 0) ...[
                          const SizedBox(height: 8),
                          _buildAmountRow(
                            'Descuento',
                            '-MXN ${order.discountAmount.toStringAsFixed(2)}',
                            valueColor: Colors.green.shade700,
                          ),
                        ],
                        const SizedBox(height: 8),
                        _buildAmountRow(
                          'Envío',
                          order.shippingCost <= 0
                              ? 'Gratis'
                              : 'MXN ${order.shippingCost.toStringAsFixed(2)}',
                          valueColor: order.shippingCost <= 0 ? Colors.green.shade700 : null,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1),
                        ),
                        _buildAmountRow(
                          'Total pagado',
                          'MXN ${order.totalAmount.toStringAsFixed(2)}',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gray),
        const SizedBox(width: 10),
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.gray)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.dark),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isBold ? AppTypography.bodyMedium : AppTypography.bodySmall).copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppColors.dark : AppColors.gray,
          ),
        ),
        Text(
          value,
          style: (isBold ? AppTypography.bodyLarge : AppTypography.bodySmall).copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppColors.dark,
          ),
        ),
      ],
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
      case 'DELIVERED':
        color = Colors.teal;
        text = 'Entregado';
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.grayLight),
          const SizedBox(height: 24),
          Text('No tienes pedidos aún', style: AppTypography.displayMedium.copyWith(color: AppColors.dark)),
        ],
      ),
    );
  }
}
