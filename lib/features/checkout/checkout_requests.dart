import 'package:enjoy_lavash_mobile/features/address/delivery_address_text.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/address_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';

/// The delivery point known on this device, as checkout sends it: a point
/// the customer picked on the map, or the phone's own position. The phone's
/// position has no [addressName] when its address could not be looked up.
typedef DeliveryPoint = ({
  double latitude,
  double longitude,
  String addressName,
  String fullAddress,
  String houseNumber,
  String apartment,
  String entrance,
  String floor,
  String comment,
});

/// Where a delivery goes: a saved address (by id) or a point on the map.
/// Exactly one of the two is set.
typedef DeliveryTarget = ({String? addressId, DeliveryPoint? point});

/// Where a delivery goes, given the [point] known on this device and the
/// customer's [savedAddresses]; null when the customer has to choose.
///
/// What the customer sees is what is sent (see `deliveryAddressText`, which
/// follows the same order): a point with an address wins; without one the
/// default saved address is used, because that is what the screens show;
/// a point without an address is sent only when nothing is saved.
DeliveryTarget? resolveDeliveryTarget({
  required DeliveryPoint? point,
  required List<ClientAddress> savedAddresses,
}) {
  final saved = defaultClientAddress(savedAddresses);
  if (point != null &&
      (trimmedOrNull(point.addressName) != null || saved == null)) {
    return (addressId: null, point: point);
  }
  if (saved != null) return (addressId: saved.id, point: null);
  return null;
}

/// Server error codes after which the loyalty wallet is reloaded and
/// checkout starts again with fresh amounts.
const Set<String> loyaltyResetErrorCodes = <String>{
  'LOYALTY_AMOUNT_CHANGED',
  'LOYALTY_DEBT_OUTSTANDING',
  'LOYALTY_REDEMPTION_DISABLED',
  'LOYALTY_PROGRAM_DISABLED',
  'IDEMPOTENCY_KEY_REUSED',
};

/// Server error codes for which the order may be retried without points.
const Set<String> pointsUnavailableErrorCodes = <String>{
  'LOYALTY_UNAVAILABLE',
  'IIKO_LOYALTY_TENDER_UNAVAILABLE',
};

/// Server error code for a branch that does not take orders right now.
const String orderingClosedErrorCode = 'ORDERING_CLOSED';

/// The order lines for [cartLines], with their modifiers.
List<CartItemInput> checkoutItems(List<CartLine> cartLines) {
  return cartLines
      .map(
        (line) => CartItemInput(
          productId: checkoutProductId(line.product),
          quantity: line.quantity,
          modifiers: line.modifiers
              .map(
                (modifier) => CartModifierInput(
                  modifierId: modifier.modifierId,
                  quantity: modifier.quantity,
                ),
              )
              .toList(growable: false),
        ),
      )
      .toList(growable: false);
}

/// The id the order uses for [product]: its iiko id when it has one.
String checkoutProductId(MenuProduct product) {
  final iikoId = product.iikoId?.trim();
  return iikoId == null || iikoId.isEmpty ? product.id : iikoId;
}

/// [point] as the order's inline delivery address.
CreateOrderAddressInput inlineOrderAddress(DeliveryPoint point) {
  final addressName = trimmedOrNull(point.addressName);
  final fullAddress = trimmedOrNull(point.fullAddress) ?? addressName;
  return CreateOrderAddressInput(
    latitude: point.latitude,
    longitude: point.longitude,
    label: addressName,
    text: fullAddress,
    street: addressName,
    houseNumber: trimmedOrNull(point.houseNumber),
    apartmentNumber: trimmedOrNull(point.apartment),
    entrance: trimmedOrNull(point.entrance),
    floor: trimmedOrNull(point.floor),
    comment: trimmedOrNull(point.comment),
  );
}

/// [point] as the cart preview's delivery location (coordinates only).
CartPreviewAddressInput previewDeliveryAddress(DeliveryPoint point) {
  return CartPreviewAddressInput(
    latitude: point.latitude,
    longitude: point.longitude,
  );
}
