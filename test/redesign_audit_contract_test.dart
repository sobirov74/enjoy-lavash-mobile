import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/catalog_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/promotion_model.dart';
import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/theme/app_theme_colors.dart';
import 'package:enjoy_lavash_mobile/utils/price_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('redesign brand palette', () {
    test(
      'uses premium orange for actions without recoloring danger states',
      () {
        expect(BaseColors.primary, const Color(0xFFC4511A));
        expect(BaseColors.primaryDark, const Color(0xFF9F3D0C));
        expect(BaseColors.surfaceTint, const Color(0xFFFCE9DD));
        expect(AppDesignTokens.action, BaseColors.primary);
        expect(AppDesignTokens.actionPressed, BaseColors.primaryDark);
        expect(AppDesignTokens.actionSoft, BaseColors.surfaceTint);
        expect(AppThemeColors.light.primary, BaseColors.primary);
        expect(AppThemeColors.dark.primary, BaseColors.primary);
        expect(BaseColors.danger, const Color(0xFFC2452D));
        expect(AppDesignTokens.danger, const Color(0xFFC2452D));
      },
    );
  });

  group('redesign catalog contracts', () {
    test('preserves categories and parses documented product metadata', () {
      final catalog = CatalogModel.fromJson({
        'categories': [
          {
            'id': 'cat-lavash',
            'name': {'ru': 'Лаваш', 'en': 'Lavash'},
            'description': {'en': 'Freshly wrapped'},
            'image': {'url': '/uploads/categories/lavash.jpg'},
            'sortOrder': 1,
            'products': [
              {
                'id': 'prod-classic',
                'name': {'en': 'Classic lavash'},
                'basePrice': 32000,
                'calories': '620',
                'weight_grams': 360.8,
                'cookingTimeMinutes': '12',
              },
            ],
          },
          {
            'id': 'cat-drinks',
            'name': {'en': 'Drinks'},
            'imageUrl': '/uploads/categories/drinks.jpg',
            'sortOrder': 2,
            'products': const <Map<String, Object?>>[],
          },
        ],
      }, language: 'en');

      expect(
        catalog.categories.map((category) => category.id),
        orderedEquals(const ['cat-lavash', 'cat-drinks']),
      );
      expect(catalog.categories.first.name, 'Lavash');
      expect(catalog.categories.first.description, 'Freshly wrapped');
      expect(catalog.categories.first.image, '/uploads/categories/lavash.jpg');
      expect(catalog.categories.last.image, '/uploads/categories/drinks.jpg');

      final product = catalog.products.single;
      expect(product.categoryId, 'cat-lavash');
      expect(product.categoryName, 'Lavash');
      expect(product.calories, 620);
      expect(product.weightGrams, 360);
      expect(product.cookingTimeMinutes, 12);
    });
  });

  group('redesign promotion contracts', () {
    test('parses public aliases and nested reward fields', () {
      final promotion = PromotionModel.fromJson({
        'id': 'promo-first20',
        'promoCode': 'FIRST20',
        'title_i18n': {
          'ru': 'Скидка 20%',
          'uz': '20% chegirma',
          'en': '20% off',
        },
        'descriptionI18n': {'ru': 'Первый заказ', 'en': 'Your first order'},
        'is_active': true,
        'startDate': '2026-07-01T00:00:00.000Z',
        'end_date': '2026-07-31T23:59:59.000Z',
        'reward': {'type': 'PERCENT', 'value': '20'},
      }, language: 'en');

      expect(promotion.code, 'FIRST20');
      expect(promotion.title, '20% off');
      expect(promotion.description, 'Your first order');
      expect(promotion.isActive, isTrue);
      expect(promotion.discountType, 'PERCENT');
      expect(promotion.discountValue, 20);
      expect(promotion.isPercentageDiscount, isTrue);
      expect(promotion.startsAt, DateTime.parse('2026-07-01T00:00:00.000Z'));
      expect(promotion.endsAt, DateTime.parse('2026-07-31T23:59:59.000Z'));
    });
  });

  group('redesign cart configuration contracts', () {
    test('quick-add refuses a required group without an explicit default', () {
      final product = _productWithOption(
        optionName: 'White sauce',
        optionPrice: 0,
        isDefault: false,
        isAvailable: true,
      );

      expect(standardCartSelection(product), isNull);
    });

    test(
      'reconciliation refreshes group, name, and price from the catalog',
      () {
        final selection = CartSelection(
          productId: 'prod-classic',
          quantity: 2,
          modifiers: const [
            CartModifierSelection(
              groupId: 'legacy-sauce-group',
              modifierId: 'mod-white',
              name: 'Old sauce name',
              price: 500,
            ),
          ],
        );
        final product = _productWithOption(
          optionName: 'Signature white sauce',
          optionPrice: 2500,
          isDefault: true,
          isAvailable: true,
        );

        final reconciled = reconcileCartSelection(selection, product);

        expect(reconciled, isNotNull);
        expect(reconciled!.quantity, 2);
        expect(reconciled.modifiers.single.groupId, 'sauce');
        expect(reconciled.modifiers.single.name, 'Signature white sauce');
        expect(reconciled.modifiers.single.price, 2500);
      },
    );

    test('reconciliation rejects a modifier that is no longer available', () {
      final selection = CartSelection(
        productId: 'prod-classic',
        quantity: 1,
        modifiers: const [
          CartModifierSelection(
            groupId: 'sauce',
            modifierId: 'mod-white',
            name: 'White sauce',
            price: 0,
          ),
        ],
      );
      final product = _productWithOption(
        optionName: 'White sauce',
        optionPrice: 0,
        isDefault: true,
        isAvailable: false,
      );

      expect(reconcileCartSelection(selection, product), isNull);
    });
  });

  group('redesign priced preview contracts', () {
    test(
      'parses paid lines, modifiers, and promotion gifts as typed items',
      () {
        final gift = <String, Object?>{
          'product_id': 'prod-cola',
          'product_name_snapshot_i18n': {
            'ru': 'Кола',
            'uz': 'Kola',
            'en': 'Cola',
          },
          'category_id': 'cat-drinks',
          'quantity': 1,
          'unit_price': 0,
          'modifiers_amount': 0,
          'total_price': 0,
          'is_bonus': true,
          'original_unit_price': 12000,
          'promotion_id': 'promo-appgift',
          'promotion_code': 'APPGIFT',
          'modifiers': const <Object?>[],
        };
        final preview = CartPreviewModel.fromJson({
          'itemsAmount': 64000,
          'modifiersAmount': 5000,
          'discountAmount': 0,
          'deliveryAmount': 10000,
          'serviceFeeAmount': 0,
          'totalAmount': 79000,
          'items': [
            {
              'productId': 'prod-classic',
              'productNameSnapshotI18n': {
                'ru': 'Классический лаваш',
                'en': 'Classic lavash',
              },
              'categoryId': 'cat-lavash',
              'quantity': 2,
              'unitPrice': 32000,
              'modifiersAmount': 5000,
              'totalPrice': 69000,
              'isBonus': false,
              'comment': 'No onion',
              'modifiers': [
                {
                  'modifierId': 'mod-cheese',
                  'modifierNameSnapshotI18n': {'ru': 'Сыр', 'en': 'Cheese'},
                  'quantity': 1,
                  'unitPrice': 5000,
                  'totalPrice': 5000,
                },
              ],
            },
            gift,
          ],
          'bonus_items': [gift],
          'appliedPromotion': {
            'id': 'promo-appgift',
            'code': 'APPGIFT',
            'titleI18n': {'ru': 'Подарок в приложении', 'en': 'App gift'},
          },
        });

        expect(preview.pricedItems, hasLength(2));
        final paid = preview.pricedItems.first;
        expect(paid.nameFor('en'), 'Classic lavash');
        expect(paid.comment, 'No onion');
        expect(paid.totalPrice, 69000);
        expect(paid.isBonus, isFalse);
        expect(paid.modifiers.single.nameFor('en'), 'Cheese');
        expect(paid.modifiers.single.unitPrice, 5000);

        final parsedGift = preview.pricedBonusItems.single;
        expect(parsedGift.nameFor('uz'), 'Kola');
        expect(parsedGift.isBonus, isTrue);
        expect(parsedGift.originalUnitPrice, 12000);
        expect(parsedGift.promotionId, 'promo-appgift');
        expect(parsedGift.promotionCode, 'APPGIFT');
        expect(preview.pricedItems.last.isBonus, isTrue);
        expect(preview.appliedPromotion?.titleFor('en'), 'App gift');
        expect(
          preview.appliedPromotion?.titleFor('ru'),
          'Подарок в приложении',
        );
      },
    );
  });

  group('redesign currency contracts', () {
    for (final entry in const <String, String>{
      'en': 'UZS',
      'ru': 'сум',
      'uz': "so'm",
    }.entries) {
      testWidgets('formats UZS using the ${entry.key} locale', (tester) async {
        const amount = 1234567;
        final expectedAmount = NumberFormat.decimalPattern(
          entry.key,
        ).format(amount);
        final expected = '$expectedAmount ${entry.value}';

        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(entry.key),
            supportedLocales: L.supportedLocales,
            localizationsDelegates: L.localizationsDelegates,
            home: Builder(
              builder: (context) => Text(formatSum(context, amount)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(expected), findsOneWidget);
      });
    }
  });
}

MenuProduct _productWithOption({
  required String optionName,
  required int optionPrice,
  required bool isDefault,
  required bool isAvailable,
}) {
  return MenuProduct(
    id: 'prod-classic',
    title: 'Classic lavash',
    price: 32000,
    category: 'Lavash',
    emoji: '🌯',
    tint: const Color(0xFFFFE0D6),
    highlight: const Color(0xFFFFF6F0),
    modifierGroups: [
      MenuModifierGroup(
        id: 'sauce',
        name: 'Choose sauce',
        minSelected: 1,
        maxSelected: 1,
        options: [
          MenuModifierOption(
            id: 'mod-white',
            name: optionName,
            price: optionPrice,
            defaultQuantity: 1,
            isDefault: isDefault,
            isAvailable: isAvailable,
          ),
        ],
      ),
    ],
  );
}
