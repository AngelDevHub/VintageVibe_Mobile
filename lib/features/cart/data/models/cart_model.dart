class CartModel {
  final int id;
  final int userId;
  final List<CartItemModel> items;
  final double total;

  CartModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: json['id'] as int,
      userId: json['userId'] as int,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CartItemModel {
  final int id;
  final int variantId;
  final String productName;
  final String variantSku;
  final String size;
  final String color;
  final double price;
  final int quantity;
  final int stock;

  CartItemModel({
    required this.id,
    required this.variantId,
    required this.productName,
    required this.variantSku,
    required this.size,
    required this.color,
    required this.price,
    required this.quantity,
    required this.stock,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as int,
      variantId: json['variantId'] as int,
      productName: json['productName'] ?? '',
      variantSku: json['variantSku'] ?? '',
      size: json['size'] ?? '',
      color: json['color'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
      stock: json['stock'] as int? ?? 0,
    );
  }

  double get subtotal => price * quantity;
}
