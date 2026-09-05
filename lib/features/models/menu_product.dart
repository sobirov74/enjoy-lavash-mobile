import 'package:flutter/material.dart';

class MenuProduct {
  const MenuProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.category,
    required this.emoji,
    required this.tint,
    required this.highlight,
    this.iikoId,
    this.imageUrl,
    this.description,
    this.calories,
    this.weightGrams,
    this.cookingTimeMinutes,
    this.modifierGroups = const <MenuModifierGroup>[],
  });

  final String id;
  final String? iikoId;
  final String title;
  final int price;
  final String category;
  final String emoji;
  final Color tint;
  final Color highlight;
  final String? imageUrl;
  final String? description;
  final int? calories;
  final int? weightGrams;
  final int? cookingTimeMinutes;
  final List<MenuModifierGroup> modifierGroups;

  bool get hasModifiers => modifierGroups.any(
    (group) => group.options.any((option) => option.isAvailable),
  );

  bool get hasRequiredModifiers =>
      modifierGroups.any((group) => group.minSelected > 0);
}

class MenuModifierGroup {
  const MenuModifierGroup({
    required this.id,
    required this.name,
    required this.minSelected,
    required this.maxSelected,
    required this.options,
  });

  final String id;
  final String name;
  final int minSelected;
  final int maxSelected;
  final List<MenuModifierOption> options;

  bool get allowsMultiple => maxSelected > 1;
}

class MenuModifierOption {
  const MenuModifierOption({
    required this.id,
    required this.name,
    required this.price,
    required this.defaultQuantity,
    required this.isDefault,
    required this.isAvailable,
    this.imageUrl,
  });

  final String id;
  final String name;
  final int price;
  final int defaultQuantity;
  final bool isDefault;
  final bool isAvailable;
  final String? imageUrl;
}
