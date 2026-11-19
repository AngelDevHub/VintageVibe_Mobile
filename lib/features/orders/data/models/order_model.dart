class OrderModel {
  final int? id;
  final double totalAmount;
  final String status;
  final String orderDate;

  OrderModel({this.id, required this.totalAmount, required this.status, required this.orderDate});

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'],
        totalAmount: json['totalAmount'] ?? 0.0,
        status: json['status'] ?? 'PENDING',
        orderDate: json['orderDate'] ?? '',
      );
}

class CheckoutRequest {
  final int addressId;
  final String paymentMethod;
  final String? couponCode;

  CheckoutRequest({required this.addressId, required this.paymentMethod, this.couponCode});

  Map<String, dynamic> toJson() => {
        'addressId': addressId,
        'paymentMethod': paymentMethod,
        'couponCode': couponCode,
      };
}
