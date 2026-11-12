import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/promotion_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('banner images resolve against the backend origin', () {
    for (final entry in <String?, String?>{
      null: null,
      '': null,
      '  ': null,
      '/uploads/banner.jpg': 'https://backend.test:8443/uploads/banner.jpg',
      'uploads/banner.jpg': 'https://backend.test:8443/uploads/banner.jpg',
      ' https://cdn.test/banner.jpg ': 'https://cdn.test/banner.jpg',
      'file:///banner.jpg': null,
    }.entries) {
      final promotion = PromotionModel.fromJson({
        'id': 'offer',
        'imageUrl': entry.key,
      }, backendBaseUrl: 'https://backend.test:8443/api/v1/');
      expect(promotion.imageUrl, entry.value, reason: '${entry.key}');
    }
    expect(PromotionModel.fromJson({'id': 'no-image'}).imageUrl, isNull);
  });
}
