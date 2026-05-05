class Product {
  final String id;
  final String name;
  final String? num;
  final String? sapCode;
  final bool? isAccessible;
  final double? minStock;
  final double? maxStock;
  final double? currentStock;
  final String? supplierId;
  final String? supplierName;
  final String? measurementUnitName;
  final String? image;

  Product({
    required this.id,
    required this.name,
    required this.num,
    required this.sapCode,
    required this.isAccessible,
    required this.minStock,
    required this.maxStock,
    this.currentStock,
    this.supplierId,
    this.supplierName,
    this.measurementUnitName,
    this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      num: json['num'] ?? '',
      sapCode: json['sap_code'] ?? '',
      isAccessible: json['is_accessible'] ?? false,
      minStock: json['min_stock'] ?? 0,
      maxStock: json['max_stock'] ?? 0,
      currentStock: json['current_stock'] ?? 0,
      supplierId: json['supplier_id'] ?? '',
      supplierName: json['supplier_name'] ?? '',
      measurementUnitName: json['measurement_unit_name'] ?? '',
      image: json['image'],
    );
  }
}
