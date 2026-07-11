import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CartStorage {
  CartStorage._();

  static const String _storageKey = 'mobile_cart_quantities';

  static Future<Map<String, int>> read() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey);
    if (encoded == null || encoded.isEmpty) return <String, int>{};

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) return <String, int>{};

      final cart = <String, int>{};
      for (final entry in decoded.entries) {
        final quantity = entry.value;
        if (quantity is int && quantity > 0) {
          cart[entry.key] = quantity;
        }
      }
      return cart;
    } on FormatException {
      await preferences.remove(_storageKey);
      return <String, int>{};
    }
  }

  static Future<void> save(Map<String, int> cart) async {
    final preferences = await SharedPreferences.getInstance();
    final sanitized = <String, int>{
      for (final entry in cart.entries)
        if (entry.key.isNotEmpty && entry.value > 0) entry.key: entry.value,
    };

    if (sanitized.isEmpty) {
      await preferences.remove(_storageKey);
      return;
    }

    await preferences.setString(_storageKey, jsonEncode(sanitized));
  }
}
