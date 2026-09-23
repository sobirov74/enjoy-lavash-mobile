import 'package:enjoy_lavash_mobile/core/api/backend_image_url.dart';

import 'json_helpers.dart';
import 'promotion_model.dart';

/// Global home content. Visibility and ordering are decided by the banner API.
class BannerModel {
  const BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.promotionId,
    this.promotion,
    this.linkUrl,
  });

  final String id;
  final String title;
  final String? imageUrl;
  final String? promotionId;
  final PromotionModel? promotion;
  final String? linkUrl;

  factory BannerModel.fromJson(
    JsonMap json, {
    String language = 'uz',
    String? backendBaseUrl,
  }) {
    final promotionJson = asJsonMap(json['promotion']);
    return BannerModel(
      id: readString(json, const ['id']),
      title: localizedText(json['titleI18n'], language),
      imageUrl: resolveBackendImageUrl(
        json['imageUrl'],
        backendBaseUrl: backendBaseUrl,
      ),
      promotionId: _nonEmpty(json['promotionId']),
      promotion: promotionJson.isEmpty
          ? null
          : PromotionModel.fromJson(
              promotionJson,
              language: language,
              backendBaseUrl: backendBaseUrl,
            ),
      linkUrl: _nonEmpty(json['linkUrl']),
    );
  }
}

String? _nonEmpty(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}
