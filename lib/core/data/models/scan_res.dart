import 'package:enjoy_lavash_mobile/core/data/models/order_product.dart';

class ScanResponse {
  final String id;
  final int number;
  final String expectedQuantity;
  final OrderProducts orderProduct;
  final bool isActive;
  final DateTime scannedAt;

  ScanResponse({
    required this.id,
    required this.number,
    required this.expectedQuantity,
    required this.orderProduct,
    required this.isActive,
    required this.scannedAt,
  });

  factory ScanResponse.fromJson(Map<String, dynamic> json) {
    return ScanResponse(
      id: json['id'],
      number: json['number'],
      expectedQuantity: json['expected_quantity'],
      orderProduct: OrderProducts.fromJson(json['order_product']),
      isActive: json['is_active'],
      scannedAt: DateTime.parse(json['scanned_at']),
    );
  }
}
