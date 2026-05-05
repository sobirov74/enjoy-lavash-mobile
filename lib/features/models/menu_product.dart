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
  });

  final String id;
  final String title;
  final int price;
  final String category;
  final String emoji;
  final Color tint;
  final Color highlight;
}
