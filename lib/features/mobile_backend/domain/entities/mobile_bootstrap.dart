import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/address_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/catalog_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/promotion_model.dart';

class MobileBootstrap {
  const MobileBootstrap({
    required this.branches,
    required this.catalog,
    required this.promotions,
    required this.paymentMethods,
    this.client,
    this.addresses = const <ClientAddress>[],
    this.orders = const <CustomerOrderModel>[],
  });

  final List<BranchModel> branches;
  final CatalogModel catalog;
  final List<PromotionModel> promotions;
  final List<PaymentMethodModel> paymentMethods;
  final ClientProfile? client;
  final List<ClientAddress> addresses;
  final List<CustomerOrderModel> orders;

  bool get isAuthenticated => client != null;
}
