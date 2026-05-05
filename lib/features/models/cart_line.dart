import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';

class CartLine {
  const CartLine({required this.product, required this.quantity});

  final MenuProduct product;
  final int quantity;
}
