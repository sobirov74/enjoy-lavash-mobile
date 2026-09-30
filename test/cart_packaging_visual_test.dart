import 'dart:io';

import 'package:enjoy_lavash_mobile/features/data/menu_catalog.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_animation/packaging_visual.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final logoBytes = File('assets/images/enjoy-logo.png').readAsBytesSync();
  final cutout = MemoryImage(logoBytes);
  final base = MemoryImage(logoBytes, scale: 2);
  final front = MemoryImage(logoBytes, scale: 3);
  final lid = MemoryImage(logoBytes, scale: 4);
  final pizza = menuProducts.singleWhere(
    (product) => product.id == 'pepperoni',
  );

  CartPackagingAssets pizzaAssets({
    Map<CartPackagingLayer, ImageProvider>? layers,
    ImageProvider? productCutout,
    Rect productRect = const Rect.fromLTWH(0.2, 0.3, 0.6, 0.5),
    Offset lidPivot = const Offset(0.5, 0.1),
  }) => CartPackagingAssets(
    kind: CartPackagingKind.pizza,
    productId: pizza.id,
    productCutout: productCutout ?? cutout,
    productRect: productRect,
    lidPivot: lidPivot,
    layers:
        layers ??
        {
          CartPackagingLayer.base: base,
          CartPackagingLayer.front: front,
          CartPackagingLayer.lid: lid,
        },
    layerRects: const {
      CartPackagingLayer.base: Rect.fromLTWH(0.08, 0.25, 0.84, 0.65),
      CartPackagingLayer.lid: Rect.fromLTWH(0.12, 0.2, 0.76, 0.66),
    },
  );

  test(
    'catalog classification matches real products and explicit containers',
    () {
      const expected = {
        'lavash-cheese': CartPackagingKind.lavash,
        'lavash-classic': CartPackagingKind.lavash,
        'lavash-set': CartPackagingKind.combo,
        'lavash-big': CartPackagingKind.lavash,
        'pepperoni': CartPackagingKind.pizza,
        'burger-classic': CartPackagingKind.burger,
        'doner-box': CartPackagingKind.none,
        'hotdog': CartPackagingKind.hotDog,
        'caesar': CartPackagingKind.none,
      };
      for (final product in menuProducts) {
        expect(classifyCartPackaging(product), expected[product.id]);
      }
      for (final (category, title, kind)
          in <(String, String, CartPackagingKind)>[
            ('Pizzalar', 'Pitsa pepperoni', CartPackagingKind.pizza),
            ('Burgers', 'Cheese burger', CartPackagingKind.burger),
            ('Lavashlar', 'Tovuqli lavash', CartPackagingKind.lavash),
            ('Гарниры', 'Картофель фри', CartPackagingKind.fries),
            ('Hot dogs', 'Classic', CartPackagingKind.hotDog),
            ('Хот-доги', 'Фирменный', CartPackagingKind.hotDog),
            ('Ichimliklar', 'Coca-Cola shisha', CartPackagingKind.bottle),
            ('Напитки', 'Вода в бутылке', CartPackagingKind.bottle),
            ('Drinks', 'Coffee cup', CartPackagingKind.cup),
            ('Ichimliklar', 'Qahva stakanda', CartPackagingKind.cup),
            ('Комбо', 'Семейный', CartPackagingKind.combo),
            ('Burgerlar', 'Burger set', CartPackagingKind.combo),
          ]) {
        expect(
          classifyCartPackaging(_product(category: category, title: title)),
          kind,
          reason: '$category / $title',
        );
      }
    },
  );

  test(
    'vague titles and decorative emojis do not invent product packaging',
    () {
      for (final title in [
        'Coca-Cola 500 ml',
        'Coffee',
        'Hot chocolate',
        'Water 0.5 L',
        'Mystery food',
        'Salad',
        'Doner box',
        'Burgerish special',
      ]) {
        expect(
          classifyCartPackaging(_product(category: 'Other', title: title)),
          CartPackagingKind.none,
          reason: title,
        );
      }
      // An established food category wins over a flavor mentioned in its title.
      expect(
        classifyCartPackaging(
          _product(category: 'Бургеры', title: 'Pizza flavor'),
        ),
        CartPackagingKind.burger,
      );
    },
  );

  test(
    'artwork must match the exact product and contain every required layer',
    () {
      final complete = pizzaAssets();
      expect(complete.isComplete, isTrue);
      expect(complete.matches(pizza), isTrue);
      expect(
        complete.matches(_product(category: 'Pizza', title: 'Other pizza')),
        isFalse,
      );
      for (final missing in complete.requiredLayers) {
        final remaining = Map<CartPackagingLayer, ImageProvider>.of(
          complete.layers,
        )..remove(missing);
        expect(pizzaAssets(layers: remaining).isComplete, isFalse);
      }
      expect(
        CartPackagingAssets(
          kind: CartPackagingKind.pizza,
          productId: pizza.id,
          layers: complete.layers,
        ).isComplete,
        isFalse,
      );
      expect(
        pizzaAssets(
          productRect: const Rect.fromLTWH(-0.1, 0, 0.5, 0.5),
        ).isComplete,
        isFalse,
      );
      expect(pizzaAssets(lidPivot: const Offset(0.5, 1.2)).isComplete, isFalse);
      expect(
        CartPackagingAssets(
          kind: CartPackagingKind.bottle,
          productId: 'sealed-bottle',
          productCutout: cutout,
          layers: const {},
        ).isComplete,
        isTrue,
      );
    },
  );

  testWidgets('failed packaging preload returns false for clean fallback', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );
    final assets = pizzaAssets(
      layers: {
        CartPackagingLayer.base: base,
        CartPackagingLayer.front: front,
        CartPackagingLayer.lid: const AssetImage(
          'assets/images/deliberately-missing-packaging-test.png',
        ),
      },
    );
    final loaded = await tester.runAsync(() => assets.preload(context));
    expect(loaded, isFalse);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pizza closes about the rear pivot over a stable proportional base',
    (tester) async {
      const foodKey = ValueKey('selected-pizza-photo');
      final assets = pizzaAssets();
      Widget host(double progress) => MaterialApp(
        home: Center(
          child: CartPackagingVisual(
            kind: CartPackagingKind.pizza,
            assets: assets,
            progress: progress,
            size: const Size(240, 160),
            product: const ColoredBox(key: foodKey, color: Colors.orange),
          ),
        ),
      );
      Finder layer(ImageProvider provider) => find.byWidgetPredicate(
        (widget) => widget is Image && widget.image == provider,
      );
      Transform lidTransform() => tester
          .widgetList<Transform>(
            find.ancestor(of: layer(lid), matching: find.byType(Transform)),
          )
          .firstWhere((transform) => transform.alignment != null);

      await tester.pumpWidget(host(0));
      final originalFoodBounds = tester.getRect(find.byKey(foodKey));
      final originalFoodLayoutSize = tester.getSize(find.byKey(foodKey));
      final originalBaseBounds = tester.getRect(layer(base));
      final originalLidMatrix = lidTransform().transform.clone();
      expect(lidTransform().alignment, const Alignment(0, -0.8));

      await tester.pumpWidget(host(0.65));
      expect(tester.getRect(layer(base)), originalBaseBounds);
      expect(tester.getSize(find.byKey(foodKey)), originalFoodLayoutSize);

      await tester.pumpWidget(host(1));
      final finalFoodBounds = tester.getRect(find.byKey(foodKey));
      final finalLidBounds = tester.getRect(layer(lid));
      expect(tester.getRect(layer(base)), originalBaseBounds);
      expect(tester.getSize(find.byKey(foodKey)), originalFoodLayoutSize);
      expect(
        finalFoodBounds.width / finalFoodBounds.height,
        closeTo(originalFoodBounds.width / originalFoodBounds.height, 0.0001),
      );
      expect(finalLidBounds.contains(finalFoodBounds.topLeft), isTrue);
      expect(finalLidBounds.contains(finalFoodBounds.bottomRight), isTrue);
      expect(lidTransform().transform, isNot(originalLidMatrix));
      expect(lidTransform().transform.entry(1, 1), closeTo(1, 0.0001));

      final stack = tester.widget<Stack>(
        find.descendant(
          of: find.byType(CartPackagingVisual),
          matching: find.byType(Stack),
        ),
      );
      int paintIndex(Finder content) {
        final positioned = tester.widget<Positioned>(
          find.ancestor(of: content, matching: find.byType(Positioned)).first,
        );
        return stack.children.indexOf(positioned);
      }

      expect(
        paintIndex(layer(base)),
        lessThan(paintIndex(find.byKey(foodKey))),
      );
      expect(
        paintIndex(find.byKey(foodKey)),
        lessThan(paintIndex(layer(front))),
      );
      expect(paintIndex(layer(front)), lessThan(paintIndex(layer(lid))));
      expect(tester.takeException(), isNull);
    },
  );
}

MenuProduct _product({required String category, required String title}) =>
    MenuProduct(
      id: 'test-product',
      title: title,
      category: category,
      price: 10000,
      emoji: '🍕',
      tint: Colors.orange,
      highlight: Colors.white,
    );
