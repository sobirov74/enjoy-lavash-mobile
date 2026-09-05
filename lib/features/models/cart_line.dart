import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';

class CartModifierSelection {
  const CartModifierSelection({
    required this.groupId,
    required this.modifierId,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  final String groupId;
  final String modifierId;
  final String name;
  final int price;
  final int quantity;

  int get totalPrice => price * quantity;

  Map<String, Object?> toJson() => <String, Object?>{
    'groupId': groupId,
    'modifierId': modifierId,
    'name': name,
    'price': price,
    'quantity': quantity,
  };

  factory CartModifierSelection.fromJson(Map<String, dynamic> json) {
    return CartModifierSelection(
      groupId: json['groupId'] as String? ?? '',
      modifierId: json['modifierId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}

class CartSelection {
  CartSelection({
    required this.productId,
    required this.quantity,
    this.modifiers = const <CartModifierSelection>[],
  }) : key = buildKey(productId, modifiers);

  final String key;
  final String productId;
  final int quantity;
  final List<CartModifierSelection> modifiers;

  CartSelection copyWith({int? quantity}) => CartSelection(
    productId: productId,
    quantity: quantity ?? this.quantity,
    modifiers: modifiers,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'productId': productId,
    'quantity': quantity,
    'modifiers': modifiers.map((modifier) => modifier.toJson()).toList(),
  };

  factory CartSelection.fromJson(Map<String, dynamic> json) {
    final rawModifiers = json['modifiers'];
    return CartSelection(
      productId: json['productId'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      modifiers: rawModifiers is List
          ? rawModifiers
                .whereType<Map>()
                .map(
                  (modifier) => CartModifierSelection.fromJson(
                    Map<String, dynamic>.from(modifier),
                  ),
                )
                .where((modifier) => modifier.modifierId.isNotEmpty)
                .toList(growable: false)
          : const <CartModifierSelection>[],
    );
  }

  static String buildKey(
    String productId,
    Iterable<CartModifierSelection> modifiers,
  ) {
    final parts =
        modifiers
            .map(
              (modifier) =>
                  '${modifier.groupId}:${modifier.modifierId}:${modifier.quantity}',
            )
            .toList(growable: false)
          ..sort();
    return parts.isEmpty ? productId : '$productId::${parts.join('|')}';
  }
}

class CartLine {
  const CartLine({
    required this.product,
    required this.quantity,
    this.modifiers = const <CartModifierSelection>[],
  });

  final MenuProduct product;
  final int quantity;
  final List<CartModifierSelection> modifiers;

  String get key => CartSelection.buildKey(product.id, modifiers);
  int get modifiersPrice =>
      modifiers.fold<int>(0, (sum, modifier) => sum + modifier.totalPrice);
  int get unitPrice => product.price + modifiersPrice;
  int get lineTotal => unitPrice * quantity;
  String get modifierSummary => modifiers
      .map(
        (modifier) => modifier.quantity > 1
            ? '${modifier.name} ×${modifier.quantity}'
            : modifier.name,
      )
      .join(' · ');

  CartSelection get selection => CartSelection(
    productId: product.id,
    quantity: quantity,
    modifiers: modifiers,
  );
}

/// Builds the server-defined standard configuration used by a menu tile's
/// quick-add action. A required group without enough explicit defaults must be
/// completed by the customer in the product details screen.
CartSelection? standardCartSelection(MenuProduct product, {int quantity = 1}) {
  final modifiers = <CartModifierSelection>[];
  for (final group in product.modifierGroups) {
    final defaults = group.options
        .where((option) => option.isAvailable && option.isDefault)
        .take(group.maxSelected > 0 ? group.maxSelected : group.options.length)
        .toList(growable: false);
    if (defaults.length < group.minSelected) return null;
    for (final option in defaults) {
      modifiers.add(
        CartModifierSelection(
          groupId: group.id,
          modifierId: option.id,
          name: option.name,
          price: option.price,
          quantity: option.defaultQuantity < 1 ? 1 : option.defaultQuantity,
        ),
      );
    }
  }
  return CartSelection(
    productId: product.id,
    quantity: quantity,
    modifiers: modifiers,
  );
}

/// Resolves a persisted configuration against the latest catalog snapshot.
/// Names and prices are refreshed, while unavailable or now-invalid choices
/// invalidate the line rather than silently changing what the customer chose.
CartSelection? reconcileCartSelection(
  CartSelection selection,
  MenuProduct product,
) {
  final groupsById = <String, MenuModifierGroup>{
    for (final group in product.modifierGroups) group.id: group,
  };
  final resolvedByGroup = <String, List<CartModifierSelection>>{};

  for (final stored in selection.modifiers) {
    var group = groupsById[stored.groupId];
    if (group == null) {
      for (final candidate in product.modifierGroups) {
        if (candidate.options.any((option) => option.id == stored.modifierId)) {
          group = candidate;
          break;
        }
      }
    }
    if (group == null) return null;

    MenuModifierOption? currentOption;
    for (final option in group.options) {
      if (option.id == stored.modifierId) {
        currentOption = option;
        break;
      }
    }
    if (currentOption == null || !currentOption.isAvailable) return null;
    final resolved = CartModifierSelection(
      groupId: group.id,
      modifierId: currentOption.id,
      name: currentOption.name,
      price: currentOption.price,
      quantity: stored.quantity < 1 ? 1 : stored.quantity,
    );
    final groupSelections = resolvedByGroup[group.id] ??=
        <CartModifierSelection>[];
    if (groupSelections.any(
      (modifier) => modifier.modifierId == resolved.modifierId,
    )) {
      return null;
    }
    groupSelections.add(resolved);
  }

  for (final group in product.modifierGroups) {
    final selectedCount = resolvedByGroup[group.id]?.length ?? 0;
    if (selectedCount < group.minSelected) return null;
    if (group.maxSelected > 0 && selectedCount > group.maxSelected) return null;
  }

  final resolvedModifiers = <CartModifierSelection>[
    for (final group in product.modifierGroups) ...?resolvedByGroup[group.id],
  ];
  return CartSelection(
    productId: product.id,
    quantity: selection.quantity,
    modifiers: resolvedModifiers,
  );
}
