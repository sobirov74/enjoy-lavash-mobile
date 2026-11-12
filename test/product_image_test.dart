import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/widgets/product_image.dart';
import 'package:enjoy_lavash_mobile/widgets/utils/cover_sized_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const MenuProduct _product = MenuProduct(
  id: 'lavash',
  title: 'Lavash',
  price: 30000,
  category: 'Lavash',
  emoji: '🌯',
  tint: Colors.orange,
  highlight: Colors.amber,
  imageUrl: 'https://example.test/lavash.jpg',
);

void main() {
  CoverSizedImage photoOf(WidgetTester tester) {
    final image = tester.widget<Image>(
      find.descendant(
        of: find.byType(ProductImage),
        matching: find.byType(Image),
      ),
    );
    return image.image as CoverSizedImage;
  }

  testWidgets('a square cart thumbnail decodes to cover a square box', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const ProductImage(product: _product, width: 52, height: 52)),
    );
    final ratio = tester.view.devicePixelRatio;

    final photo = photoOf(tester);
    expect(photo.width, coverDecodeExtent(52, ratio));
    expect(photo.height, coverDecodeExtent(52, ratio));
  });

  testWidgets('a known layout width is used without measuring', (tester) async {
    await tester.pumpWidget(
      _host(
        const ProductImage(
          product: _product,
          width: double.infinity,
          height: 106,
          layoutWidth: 170,
        ),
      ),
    );
    final ratio = tester.view.devicePixelRatio;

    final photo = photoOf(tester);
    expect(photo.width, coverDecodeExtent(170, ratio));
    expect(photo.height, coverDecodeExtent(106, ratio));
    expect(
      find.descendant(
        of: find.byType(ProductImage),
        matching: find.byType(LayoutBuilder),
      ),
      findsNothing,
    );
  });

  testWidgets('without a layout width the photo measures its box', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 120,
          child: ProductImage(
            product: _product,
            width: double.infinity,
            height: 70,
          ),
        ),
      ),
    );
    final ratio = tester.view.devicePixelRatio;

    final photo = photoOf(tester);
    expect(photo.width, coverDecodeExtent(120, ratio));
    expect(photo.height, coverDecodeExtent(70, ratio));
  });

  testWidgets('a placeholder box shows that smaller decode first', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const ProductImage(
          product: _product,
          width: 300,
          height: 300,
          placeholderBox: Size(160, 106),
        ),
      ),
    );
    final ratio = tester.view.devicePixelRatio;

    final images = tester
        .widgetList<Image>(
          find.descendant(
            of: find.byType(ProductImage),
            matching: find.byType(Image),
          ),
        )
        .map((image) => image.image as CoverSizedImage)
        .toList();
    // The large photo has no frame yet, so its frame builder shows the
    // grid-sized decode (which is already in memory when the grid showed it).
    expect(images.map((image) => image.width), <int>[
      coverDecodeExtent(300, ratio),
      coverDecodeExtent(160, ratio),
    ]);
  });
}

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}
