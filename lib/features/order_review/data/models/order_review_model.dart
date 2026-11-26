import 'package:enjoy_lavash_mobile/core/api/backend_image_url.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/json_helpers.dart';

class OrderReviewModel {
  OrderReviewModel({
    required this.id,
    required this.rating,
    this.comment,
    List<OrderReviewPhotoModel> photos = const [],
    this.createdAt,
  }) : photos = List<OrderReviewPhotoModel>.unmodifiable(photos);

  final String id;
  final int rating;
  final String? comment;
  final List<OrderReviewPhotoModel> photos;
  final DateTime? createdAt;

  factory OrderReviewModel.fromJson(JsonMap json, {String? backendBaseUrl}) {
    return OrderReviewModel(
      id: readString(json, const ['id']),
      rating: readInt(json, const ['rating']),
      comment: stringOrNull(json['comment']),
      photos: asJsonMapList(json['photos'])
          .map(
            (photo) => OrderReviewPhotoModel.fromJson(
              photo,
              backendBaseUrl: backendBaseUrl,
            ),
          )
          .toList(growable: false),
      createdAt: readDateTime(json, const ['createdAt']),
    );
  }
}

class OrderReviewPhotoModel {
  const OrderReviewPhotoModel({
    required this.url,
    required this.width,
    required this.height,
  });

  final String url;
  final int width;
  final int height;

  factory OrderReviewPhotoModel.fromJson(
    JsonMap json, {
    String? backendBaseUrl,
  }) {
    return OrderReviewPhotoModel(
      url:
          resolveBackendImageUrl(json['url'], backendBaseUrl: backendBaseUrl) ??
          '',
      width: readInt(json, const ['width']),
      height: readInt(json, const ['height']),
    );
  }
}
