class OrderProducts {
  final String id;
  final double orderedUnits;
  final double roundedOrderedUnits;
  final double? shippedUnits;
  final double? deliveredUnits;

  final Product product;

  OrderProducts({
    required this.id,
    required this.orderedUnits,
    required this.roundedOrderedUnits,
    required this.shippedUnits,
    required this.deliveredUnits,
    required this.product,
  });

  factory OrderProducts.fromJson(Map<String, dynamic> json) {
    return OrderProducts(
      id: json['id'],
      orderedUnits: json['ordered_units'] ?? 0,
      roundedOrderedUnits: json['rounded_ordered_units'] ?? 0,
      shippedUnits: json['shipped_units'] ?? 0,
      deliveredUnits: json['delivered_units'],
      product: Product.fromJson(json['product']),
    );
  }
}

class Product {
  final String id;
  final String name;
  final String? num;
  final String? sapCode;

  Product({
    required this.id,
    required this.name,
    required this.num,
    required this.sapCode,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      num: json['num'],
      sapCode: json['sap_code'],
    );
  }
}
