class OrderItemModel {
  final int? id;
  final int? variantId;
  final String productName;
  final String variantSku;
  final String size;
  final String color;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItemModel({
    this.id,
    this.variantId,
    required this.productName,
    required this.variantSku,
    required this.size,
    required this.color,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num?)?.toInt() ?? 1;
    final unit = (json['unitPrice'] as num?)?.toDouble() ?? 0.0;
    final total = (json['totalPrice'] as num?)?.toDouble() ?? (unit * qty);
    return OrderItemModel(
      id: (json['id'] as num?)?.toInt(),
      variantId: (json['variantId'] as num?)?.toInt(),
      productName: json['productName']?.toString() ?? 'Prenda vintage',
      variantSku: json['variantSku']?.toString() ?? '',
      size: json['size']?.toString() ?? 'U',
      color: json['color']?.toString() ?? 'N/A',
      quantity: qty,
      unitPrice: unit,
      totalPrice: total,
    );
  }
}

class OrderModel {
  final int? id;
  final String orderNumber;
  final double subtotal;
  final double discountAmount;
  final double shippingCost;
  final double totalAmount;
  final String status;
  final String orderDate;
  final DateTime? createdAt;
  final String? shippingFullName;
  final String? shippingCity;
  final String? shippingCountry;
  final String? paymentMethod;
  final List<OrderItemModel> items;

  OrderModel({
    this.id,
    this.orderNumber = '',
    this.subtotal = 0.0,
    this.discountAmount = 0.0,
    this.shippingCost = 0.0,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    this.createdAt,
    this.shippingFullName,
    this.shippingCity,
    this.shippingCountry,
    this.paymentMethod,
    this.items = const [],
  });

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is String && raw.trim().isNotEmpty) {
      return DateTime.tryParse(raw.trim());
    }
    if (raw is List && raw.length >= 3) {
      final y = (raw[0] as num).toInt();
      final m = (raw[1] as num).toInt();
      final d = (raw[2] as num).toInt();
      final hh = raw.length > 3 ? (raw[3] as num).toInt() : 0;
      final mm = raw.length > 4 ? (raw[4] as num).toInt() : 0;
      final ss = raw.length > 5 ? (raw[5] as num).toInt() : 0;
      return DateTime(y, m, d, hh, mm, ss);
    }
    return null;
  }

  String get formattedDate {
    final dt = createdAt ?? _parseDate(orderDate);
    if (dt == null) {
      return orderDate.isNotEmpty ? orderDate.split('T').first : 'Sin fecha';
    }
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[(dt.month - 1).clamp(0, 11)];
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day $month ${dt.year} · $hour:$min';
  }

  String get formattedPaymentMethod {
    switch ((paymentMethod ?? '').toUpperCase()) {
      case 'CARD':
      case 'CREDIT_CARD':
        return 'Tarjeta de crédito';
      case 'DEBIT_CARD':
        return 'Tarjeta de débito';
      case 'PAYPAL':
        return 'PayPal';
      case 'TRANSFER':
      case 'BANK_TRANSFER':
        return 'Transferencia bancaria';
      case 'CASH_ON_DELIVERY':
        return 'Pago contra entrega';
      default:
        return (paymentMethod != null && paymentMethod!.isNotEmpty)
            ? paymentMethod!
            : 'Pago electrónico';
    }
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['createdAt'] ?? json['orderDate'];
    final parsedDate = _parseDate(rawDate);
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final total = (json['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final sub = (json['subtotal'] as num?)?.toDouble() ?? total;

    return OrderModel(
      id: (json['id'] as num?)?.toInt(),
      orderNumber: json['orderNumber']?.toString() ?? '',
      subtotal: sub,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      shippingCost: (json['shippingCost'] as num?)?.toDouble() ?? 0.0,
      totalAmount: total,
      status: json['status']?.toString() ?? 'PENDING',
      orderDate: rawDate is String
          ? rawDate
          : (parsedDate?.toIso8601String() ?? ''),
      createdAt: parsedDate,
      shippingFullName: json['shippingFullName']?.toString(),
      shippingCity: json['shippingCity']?.toString(),
      shippingCountry: json['shippingCountry']?.toString(),
      paymentMethod: json['paymentMethod']?.toString(),
      items: rawItems
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CheckoutRequest {
  final int addressId;
  final String paymentMethod;
  final String? couponCode;

  CheckoutRequest({
    required this.addressId,
    required this.paymentMethod,
    this.couponCode,
  });

  Map<String, dynamic> toJson() => {
        'addressId': addressId,
        'paymentMethod': paymentMethod,
        'couponCode': couponCode,
      };
}
