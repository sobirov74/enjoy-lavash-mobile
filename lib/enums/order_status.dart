// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

enum OrderStatus {
  NEW,
  ACCEPTED,
  CANCELLED,
  ON_WAY,
  DELIVERED;

  factory OrderStatus.fromJson(String? value) {
    switch (value) {
      case "NEW":
        return OrderStatus.NEW;
      case "ACCEPTED":
        return OrderStatus.ACCEPTED;
      case "CANCELLED":
        return OrderStatus.CANCELLED;
      case "IN_DELIVERY":
        return OrderStatus.ON_WAY;
      case "DELIVERED":
        return OrderStatus.DELIVERED;
      default:
        return OrderStatus.NEW;
    }
  }

  String toJson() {
    switch (this) {
      case OrderStatus.NEW:
        return "NEW";
      case OrderStatus.ACCEPTED:
        return "ACCEPTED";
      case OrderStatus.CANCELLED:
        return "CANCELLED";
      case OrderStatus.ON_WAY:
        return "IN_DELIVERY";
      case OrderStatus.DELIVERED:
        return "DELIVERED";
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.NEW:
        return 'Новый';
      case OrderStatus.ACCEPTED:
        return 'Принят';
      case OrderStatus.CANCELLED:
        return 'Отменён';
      case OrderStatus.ON_WAY:
        return 'В пути';
      case OrderStatus.DELIVERED:
        return 'Доставлен';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.NEW:
        return const Color(0xFF2196F3);
      case OrderStatus.ACCEPTED:
        return const Color(0xFF9C27B0);
      case OrderStatus.ON_WAY:
        return const Color(0xFFFF9800);
      case OrderStatus.DELIVERED:
        return const Color(0xFF4CAF50);
      case OrderStatus.CANCELLED:
        return const Color(0xFFF44336);
    }
  }
}
