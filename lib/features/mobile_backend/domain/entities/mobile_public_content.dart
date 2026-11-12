import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/banner_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/catalog_model.dart';

/// The public part of a bootstrap as last saved on the device: shown at a
/// cold start until the network answers. Never holds customer data.
class MobilePublicContent {
  const MobilePublicContent({
    required this.branches,
    required this.catalog,
    required this.banners,
  });

  final List<BranchModel> branches;
  final CatalogModel catalog;
  final List<BannerModel> banners;
}
