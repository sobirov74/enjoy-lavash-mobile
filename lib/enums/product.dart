enum ProductUsageType {
  sale,
  rent;

  factory ProductUsageType.fromJson(String? value) {
    switch (value) {
      case "SALE":
        return ProductUsageType.sale;
      case "RENT":
        return ProductUsageType.rent;
      default:
        return ProductUsageType.sale;
    }
  }

  String toJson() {
    switch (this) {
      case ProductUsageType.sale:
        return "SALE";
      case ProductUsageType.rent:
        return "RENT";
    }
  }
}
