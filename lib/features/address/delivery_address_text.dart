import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/address_model.dart';

/// [value] trimmed, or null when it is null or blank.
String? trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

/// The customer's default saved address, else the first one; null when
/// there are none.
ClientAddress? defaultClientAddress(List<ClientAddress> addresses) {
  if (addresses.isEmpty) return null;
  for (final address in addresses) {
    if (address.isDefault) return address;
  }
  return addresses.first;
}

/// "Street, house, apartment" of a saved address, else its label.
String? clientAddressText(ClientAddress address) {
  final parts = <String>[
    if (address.street.trim().isNotEmpty) address.street.trim(),
    if (address.houseNumber?.trim().isNotEmpty == true)
      address.houseNumber!.trim(),
    if (address.apartmentNumber?.trim().isNotEmpty == true)
      address.apartmentNumber!.trim(),
  ];
  if (parts.isEmpty) return trimmedOrNull(address.label);
  return parts.join(', ');
}

/// The delivery address shown by the shell (Home's order-context pill) and
/// checkout: the point known on this device when it has an address (its
/// full text, else its name), else the default saved address. Checkout
/// sends the same one (`resolveDeliveryTarget`).
///
/// The menu tab formats its pill slightly differently (see `MenuScreen`);
/// that difference is recorded in docs/PERFORMANCE_PASS_2.md.
String? deliveryAddressText({
  required String addressName,
  required String fullAddress,
  required List<ClientAddress> savedAddresses,
}) {
  final name = trimmedOrNull(addressName);
  // Without a name the point is the phone's position whose address could
  // not be looked up; a house number typed for it is not an address.
  if (name != null) return trimmedOrNull(fullAddress) ?? name;
  final saved = defaultClientAddress(savedAddresses);
  return saved == null ? null : clientAddressText(saved);
}
