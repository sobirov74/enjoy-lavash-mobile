part of 'package:enjoy_lavash_mobile/screens/profile.dart';

String _notificationSubtitle(
  L t, {
  required bool isLoading,
  required bool supported,
  required bool enabled,
  required bool permissionPermanentlyDenied,
}) {
  if (isLoading) {
    return t.notificationCheckingPermission;
  }
  if (!supported) {
    return t.notificationsUnavailable;
  }
  if (enabled) {
    return t.notificationsEnabled;
  }
  if (permissionPermanentlyDenied) {
    return t.allowNotificationsInSettings;
  }
  return t.notificationsSubtitleDefault;
}

String _formatOrderAmount(int amount) {
  final text = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(text[i]);
  }
  buffer.write(" so'm");
  return buffer.toString();
}

String _formatOrderDate(DateTime? date, String locale) {
  if (date == null) return '';
  return DateFormat.yMMMMd(locale).format(date.toLocal());
}

String _formatOrderDateTime(DateTime? date, String locale) {
  if (date == null) return '';
  return DateFormat.yMMMd(locale).add_Hm().format(date.toLocal());
}

String _shortOrderId(String id) {
  final value = id.trim();
  if (value.length <= 8) return value;
  return value.substring(value.length - 8).toUpperCase();
}

String _statusLabel(MobileOrderStatus status, L t) {
  return switch (status) {
    MobileOrderStatus.newOrder => t.statusNew,
    MobileOrderStatus.confirmed => t.statusAccepted,
    MobileOrderStatus.cooking => t.orderStatusCooking,
    MobileOrderStatus.ready => t.orderStatusReady,
    MobileOrderStatus.courierAssigned => t.orderStatusCourierAssigned,
    MobileOrderStatus.onTheWay => t.orderStatusOnTheWay,
    MobileOrderStatus.delivered => t.statusCompleted,
    MobileOrderStatus.cancelled => t.statusCancelled,
    MobileOrderStatus.refunded => t.statusFailed,
    MobileOrderStatus.unknown => t.unknown,
  };
}

({Color bg, Color text}) _statusColors(MobileOrderStatus status) {
  return switch (status) {
    MobileOrderStatus.delivered || MobileOrderStatus.ready => (
      bg: const Color(0xFFE7F6EA),
      text: BaseColors.success,
    ),
    MobileOrderStatus.cancelled || MobileOrderStatus.refunded => (
      bg: const Color(0xFFFDE8E8),
      text: BaseColors.danger,
    ),
    MobileOrderStatus.unknown => (
      bg: const Color(0xFFEDEAE6),
      text: BaseColors.textGray,
    ),
    _ => (bg: const Color(0xFFFFF3E0), text: const Color(0xFFE65100)),
  };
}

({Color bg, Color border, Color accent}) _statusSurfaceColors(
  MobileOrderStatus status,
  bool isDark,
) {
  final accent = switch (status) {
    MobileOrderStatus.newOrder => const Color(0xFF3B82F6),
    MobileOrderStatus.confirmed => const Color(0xFF22C55E),
    MobileOrderStatus.cooking => const Color(0xFFF59E0B),
    MobileOrderStatus.ready => const Color(0xFF10B981),
    MobileOrderStatus.courierAssigned => const Color(0xFF38BDF8),
    MobileOrderStatus.onTheWay => const Color(0xFF6366F1),
    MobileOrderStatus.delivered => const Color(0xFF16A34A),
    MobileOrderStatus.cancelled => BaseColors.danger,
    MobileOrderStatus.refunded => const Color(0xFFEC4899),
    MobileOrderStatus.unknown => BaseColors.textGray,
  };
  final base = isDark ? const Color(0xFF2A2522) : Colors.white;

  return (
    bg: Color.alphaBlend(accent.withValues(alpha: isDark ? 0.18 : 0.09), base),
    border: accent.withValues(alpha: isDark ? 0.36 : 0.22),
    accent: accent,
  );
}

String _orderTypeLabel(MobileOrderType type, L t) {
  return switch (type) {
    MobileOrderType.delivery => t.delivery,
    MobileOrderType.pickup => t.pickup,
  };
}

IconData _orderTypeIcon(MobileOrderType type) {
  return switch (type) {
    MobileOrderType.delivery => Icons.delivery_dining_rounded,
    MobileOrderType.pickup => Icons.store_mall_directory_rounded,
  };
}

String _paymentMethodLabel(MobilePaymentMethod method, L t) {
  return switch (method) {
    MobilePaymentMethod.cash => t.paymentCash,
    MobilePaymentMethod.cardTerminal => t.paymentCardTerminal,
    MobilePaymentMethod.payme => 'Payme',
    MobilePaymentMethod.click => 'Click',
    MobilePaymentMethod.unknown => t.unknown,
  };
}

String _paymentStatusLabel(MobilePaymentStatus status, L t) {
  return switch (status) {
    MobilePaymentStatus.pending => t.paymentStatusPending,
    MobilePaymentStatus.paid => t.paymentStatusPaid,
    MobilePaymentStatus.failed => t.paymentStatusFailed,
    MobilePaymentStatus.refunded => t.paymentStatusRefunded,
    MobilePaymentStatus.unknown => t.unknown,
  };
}

String _orderProductTitle(CustomerOrderItemModel item, L t) {
  final language = t.localeName.split('_').first;
  final name = item.localizedName(language);
  if (name != null && name.isNotEmpty) return name;

  final productId = item.productId.trim();
  final fallback = t.product;
  if (productId.isEmpty) return fallback;
  return '$fallback $productId';
}

String _orderProductSummary(CustomerOrderModel order, L t) {
  if (order.items.isEmpty) {
    return t.noProductsInOrder;
  }

  final items = order.items
      .map((item) => '${_orderProductTitle(item, t)} x${item.quantity}')
      .toList(growable: false);
  final visibleItems = items.take(2).toList(growable: false);
  final extraCount = items.length - visibleItems.length;
  if (extraCount <= 0) return visibleItems.join(', ');
  return '${visibleItems.join(', ')} +$extraCount';
}

BranchModel? _findBranch(List<BranchModel> branches, String? id) {
  final branchId = id?.trim();
  if (branchId == null || branchId.isEmpty) return null;
  for (final branch in branches) {
    if (branch.id == branchId) return branch;
  }
  return null;
}

ClientAddress? _findAddress(List<ClientAddress> addresses, String? id) {
  final addressId = id?.trim();
  if (addressId == null || addressId.isEmpty) return null;
  for (final address in addresses) {
    if (address.id == addressId) return address;
  }
  return null;
}

String _formatOrderAddress(ClientAddress address, L t) {
  final primaryParts = <String>[
    if (address.street.trim().isNotEmpty) address.street.trim(),
    if (address.houseNumber?.trim().isNotEmpty == true)
      address.houseNumber!.trim(),
  ];
  final detailParts = <String>[
    if (address.apartmentNumber?.trim().isNotEmpty == true)
      '${t.apartmentLabel} ${address.apartmentNumber!.trim()}',
    if (address.entrance?.trim().isNotEmpty == true)
      '${t.entranceLabel} ${address.entrance!.trim()}',
    if (address.floor?.trim().isNotEmpty == true)
      '${t.floorLabel} ${address.floor!.trim()}',
  ];

  final primary = primaryParts.isEmpty
      ? address.label.trim()
      : primaryParts.join(', ');
  if (detailParts.isEmpty) return primary;
  return '$primary\n${detailParts.join(', ')}';
}

String? _orderDestination(
  CustomerOrderModel order,
  List<BranchModel> branches,
  List<ClientAddress> addresses,
  L t,
) {
  if (order.type == MobileOrderType.pickup) {
    final branch = _findBranch(branches, order.branchId);
    if (branch == null) return order.branchId;

    final address = branch.address?.trim();
    if (address == null || address.isEmpty) return branch.name;
    return '${branch.name}\n$address';
  }

  final address = _findAddress(addresses, order.addressId);
  if (address == null) return order.addressId;
  return _formatOrderAddress(address, t);
}

List<OrderStatusLogModel> _statusEntries(CustomerOrderModel order) {
  if (order.statusLog.isNotEmpty) return order.statusLog;
  return <OrderStatusLogModel>[
    OrderStatusLogModel(
      status: order.status,
      changedAt: order.updatedAt ?? order.createdAt,
    ),
  ];
}
