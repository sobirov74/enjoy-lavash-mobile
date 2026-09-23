import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/promotion_model.dart';
import 'package:enjoy_lavash_mobile/widgets/home_banner_slider.dart';
import 'package:enjoy_lavash_mobile/widgets/banner_image_card.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/banner_model.dart';
import 'package:enjoy_lavash_mobile/features/data/menu_catalog.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_category.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/home_screen.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home hides missing images and empty banner responses', (
    tester,
  ) async {
    await tester.pumpWidget(
      _homeWithBanners(const [
        BannerModel(id: 'missing', title: 'Missing', imageUrl: null),
        BannerModel(id: 'empty', title: 'Empty', imageUrl: '  '),
      ]),
    );
    expect(find.byType(HomeBannerSlider), findsNothing);
    await tester.pumpWidget(_homeWithBanners(const []));
    expect(find.byType(HomeBannerSlider), findsNothing);
  });

  testWidgets('home preserves banner order and opens the linked promotion', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _homeWithBanners(const [
        BannerModel(
          id: 'first',
          title: 'First banner',
          imageUrl: 'https://example.test/first.jpg',
        ),
        BannerModel(
          id: 'second',
          title: 'Second banner',
          imageUrl: 'https://example.test/second.jpg',
          promotionId: 'promotion-20',
          // The banner image and title belong to the banner, not the promotion.
          promotion: PromotionModel(
            id: 'promotion-20',
            title: 'Twenty percent off',
            isActive: true,
            code: 'SAVE20',
            discountType: 'PERCENT',
            discountValue: 20,
          ),
          linkUrl: 'enjoylavash://menu',
        ),
      ], onLinkTap: (_) => fail('Promotion must take precedence over link')),
    );
    await tester.pumpAndSettle();
    final slider = find.byType(HomeBannerSlider);
    final image = tester.widget<Image>(
      find.descendant(of: slider, matching: find.byType(Image)).first,
    );
    expect((image.image as NetworkImage).url, 'https://example.test/first.jpg');
    await tester.drag(slider, const Offset(-350, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-banner-second')));
    await tester.pumpAndSettle();
    expect(find.text('Twenty percent off'), findsOneWidget);
    expect(find.text('SAVE20'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final link in ['enjoylavash://menu', 'https://example.test/offers']) {
    testWidgets('home forwards supported link $link', (tester) async {
      Uri? opened;
      await tester.pumpWidget(
        _homeWithBanners([
          BannerModel(
            id: 'link',
            title: 'Browse',
            imageUrl: 'https://example.test/banner.jpg',
            linkUrl: link,
          ),
        ], onLinkTap: (uri) => opened = uri),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-banner-link')));
      expect(opened.toString(), link);
    });
  }

  for (final link in [null, 'javascript:alert(1)', 'enjoylavash://unknown']) {
    testWidgets('banner has no action for target $link', (tester) async {
      await tester.pumpWidget(
        _homeWithBanners([
          BannerModel(
            id: 'plain',
            title: 'Welcome',
            imageUrl: 'https://example.test/banner.jpg',
            linkUrl: link,
          ),
        ], onLinkTap: (_) => fail('No destination should open')),
      );
      await tester.pumpAndSettle();
      final card = find.byType(BannerImageCard);
      expect(tester.widget<BannerImageCard>(card).onTap, isNull);
      expect(
        find.descendant(of: card, matching: find.byIcon(Icons.chevron_right)),
        findsNothing,
      );
      await tester.tap(card);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('refresh replaces banners and handles a shrinking carousel', (
    tester,
  ) async {
    const first = BannerModel(
      id: 'first',
      title: 'First',
      imageUrl: 'https://example.test/first.jpg',
    );
    const second = BannerModel(
      id: 'second',
      title: 'Second',
      imageUrl: 'https://example.test/second.jpg',
    );
    await tester.pumpWidget(_homeWithBanners(const [first, second]));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(HomeBannerSlider), const Offset(-700, 0));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_homeWithBanners(const [first]));
    await tester.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsNothing);
    await tester.pumpWidget(_homeWithBanners(const []));
    await tester.pumpAndSettle();
    expect(find.byType(HomeBannerSlider), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home category image uses the shared thumbnail radius', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final product = menuProducts.first;
    final category = MenuCategory(id: 'lavash', name: product.category);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: Scaffold(
          body: HomeScreen(
            customerName: 'Guest',
            loyaltyBalance: 0,
            orderModeLabel: 'Delivery',
            orderContextLabel: 'Choose address',
            categories: <MenuCategory>[category],
            products: <MenuProduct>[product],
            banners: const [],
            onBannerLinkTap: (_) {},
            locale: 'en',
            onOrderContextTap: () {},
            onNotificationsTap: () {},
            onLoyaltyTap: () {},
            onMenuTap: () {},
            onCategoryTap: (_) {},
            onRefresh: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final imageClip = find.byKey(
      const ValueKey<String>('home-category-image-lavash'),
    );
    expect(imageClip, findsOneWidget);
    expect(
      tester.widget<ClipRRect>(imageClip).borderRadius,
      BorderRadius.circular(AppDesignTokens.radiusThumb),
    );
    expect(
      find.descendant(of: imageClip, matching: find.byType(ProductImage)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _homeWithBanners(
  List<BannerModel> banners, {
  ValueChanged<Uri>? onLinkTap,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: L.localizationsDelegates,
    supportedLocales: L.supportedLocales,
    home: Scaffold(
      body: HomeScreen(
        customerName: 'Guest',
        loyaltyBalance: 0,
        orderModeLabel: 'Delivery',
        orderContextLabel: 'Choose address',
        categories: const [],
        products: const [],
        banners: banners,
        onBannerLinkTap: onLinkTap ?? (_) {},
        locale: 'en',
        onOrderContextTap: () {},
        onNotificationsTap: () {},
        onLoyaltyTap: () {},
        onMenuTap: () {},
        onCategoryTap: (_) {},
        onRefresh: () async {},
      ),
    ),
  );
}
