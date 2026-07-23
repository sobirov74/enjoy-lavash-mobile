import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/assigned_promotion_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a nested assigned promotion into stable display fields', () {
    final promotion = AssignedPromotionModel.fromJson({
      'id': 'assignment-1',
      'promotionId': 'promotion-1',
      'code': 'PRIVATE20-ABC',
      'status': 'ACTIVE',
      'remainingUses': 2,
      'promotion': {
        'title': {'uz': 'Maxsus chegirma', 'ru': 'Специальная скидка'},
        'description': {'uz': 'Faqat siz uchun'},
        'discountType': 'PERCENTAGE',
        'discountValue': 20,
        'conditions': [
          {
            'text': {'uz': "100 000 so'mdan boshlab"},
          },
        ],
        'startsAt': '2026-07-20T00:00:00.000Z',
        'endsAt': '2026-07-31T23:59:59.000Z',
      },
    }, language: 'uz');

    expect(promotion.promotionAssignmentId, 'assignment-1');
    expect(promotion.promotionId, 'promotion-1');
    expect(promotion.code, 'PRIVATE20-ABC');
    expect(promotion.status, AssignedPromotionStatus.active);
    expect(promotion.canBeUsed, isTrue);
    expect(promotion.title, 'Maxsus chegirma');
    expect(promotion.description, 'Faqat siz uchun');
    expect(promotion.reward, '20%');
    expect(promotion.conditions, ["100 000 so'mdan boshlab"]);
    expect(promotion.remainingUses, 2);
    expect(promotion.endsAt, DateTime.parse('2026-07-31T23:59:59.000Z'));
  });

  test('maps every terminal assignment status', () {
    expect(
      AssignedPromotionStatus.fromJson('GLOBAL_LIMIT_REACHED'),
      AssignedPromotionStatus.globalLimitReached,
    );
    expect(
      AssignedPromotionStatus.fromJson('revoked'),
      AssignedPromotionStatus.revoked,
    );
    expect(
      AssignedPromotionStatus.fromJson('new-backend-status'),
      AssignedPromotionStatus.unknown,
    );
  });
}
