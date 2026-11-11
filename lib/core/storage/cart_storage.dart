import 'dart:convert';

import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

class CartStorage {
  CartStorage._();

  static const String _storageKey = 'mobile_cart_quantities';
  static const String _linesStorageKey = 'mobile_cart_lines_v2';

  static Future<List<CartSelection>> readSelections() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedLines = preferences.getString(_linesStorageKey);
    if (encodedLines?.isNotEmpty == true) {
      try {
        final decoded = jsonDecode(encodedLines!);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map(
                (line) =>
                    CartSelection.fromJson(Map<String, dynamic>.from(line)),
              )
              .where((line) => line.productId.isNotEmpty && line.quantity > 0)
              .toList(growable: false);
        }
      } catch (error) {
        // Corrupt or wrong-typed data from an older build. Drop it once so it
        // cannot fail every launch; the cart simply starts empty.
        debugPrint('Discarding unreadable saved cart: ${error.runtimeType}');
        await preferences.remove(_linesStorageKey);
      }
    }

    final legacy = await read();
    return legacy.entries
        .map(
          (entry) => CartSelection(productId: entry.key, quantity: entry.value),
        )
        .toList(growable: false);
  }

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
    } catch (error) {
      debugPrint('Discarding unreadable legacy cart: ${error.runtimeType}');
      await preferences.remove(_storageKey);
      return <String, int>{};
    }
  }

  static Future<void> saveSelections(Iterable<CartSelection> cart) async {
    final preferences = await SharedPreferences.getInstance();
    final sanitized = cart
        .where((line) => line.productId.isNotEmpty && line.quantity > 0)
        .map((line) => line.toJson())
        .toList(growable: false);

    if (sanitized.isEmpty) {
      await preferences.remove(_linesStorageKey);
      await preferences.remove(_storageKey);
      return;
    }

    await preferences.setString(_linesStorageKey, jsonEncode(sanitized));
    await preferences.remove(_storageKey);
  }
}
