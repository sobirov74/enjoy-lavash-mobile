import 'dart:math' as math;

import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:flutter/material.dart';

enum CartPackagingKind {
  pizza,
  burger,
  lavash,
  fries,
  hotDog,
  cup,
  bottle,
  combo,
  none,
}

enum CartPackagingLayer {
  base,
  rear,
  front,
  lid,
  bottomFold,
  leftFold,
  rightFold,
  finalFold,
  sleeve,
}

/// Classifies actual catalog text, never the decorative/fallback product emoji.
/// Drink packaging needs an explicit container clue; volume and brand names do
/// not establish whether a drink is supplied in a cup or a sealed bottle.
CartPackagingKind classifyCartPackaging(MenuProduct product) {
  final category = _catalogWords(product.category);
  final title = _catalogWords(product.title);
  final all = '$category $title';
  if (_hasWord(all, 'combo|combos|kombo|комбо|set|sets|сет|сеты|сети') ||
      all.contains('to plam')) {
    return CartPackagingKind.combo;
  }
  for (final text in [category, title]) {
    if (_hasWord(text, 'pizza|pizzas|pitsa|pitsalar|пицца|пиццы|пиццалар')) {
      return CartPackagingKind.pizza;
    }
    if (_hasWord(text, 'burger|burgers|burgerlar|бургер|бургеры|бургерлар')) {
      return CartPackagingKind.burger;
    }
    if (_hasWord(text, 'lavash|lavashlar|лаваш|лавашлар|лаваши')) {
      return CartPackagingKind.lavash;
    }
    if (_hasWord(text, 'fries|fri|фри')) return CartPackagingKind.fries;
    if (_hasWord(
      text,
      'hotdog|hotdogs|hotdoglar|hot dog|hot dogs|hot doglar|xot dog|хот дог|хот доги|хот доглар|хотдог|хотдоги',
    )) {
      return CartPackagingKind.hotDog;
    }
  }
  if (_hasWord(
    all,
    'bottle|bottled|бутылка|бутылке|бутылки|бутылочный|butilka|shisha|шиша|pet',
  )) {
    return CartPackagingKind.bottle;
  }
  if (_hasWord(all, 'cup|cups|стакан|стакане|стаканда|stakan|stakanda')) {
    return CartPackagingKind.cup;
  }
  return CartPackagingKind.none;
}

String _catalogWords(String value) =>
    value.toLowerCase().replaceAll(RegExp('[^a-zа-яёўқғҳ0-9]+'), ' ').trim();

bool _hasWord(String value, String alternatives) =>
    RegExp('(?:^| )(?:$alternatives)(?: |\$)').hasMatch(value);

/// Approved, transparent PNG/WebP artwork for ONE exact selected product.
///
/// Asset contract:
/// * [productCutout] depicts [productId], with its actual toppings/options. A
///   generic pizza, extracted logo or generated substitute is not sufficient.
/// * [productRect] contains the packed product in the normalized 0..1 canvas.
///   The supplied product widget begins at the full source rectangle and scales
///   uniformly into this region, retaining its aspect ratio and original layout.
/// * Each layer is cropped to its own [layerRects] entry (default full canvas),
///   with transparent margins and consistent lighting/perspective. Artwork
///   should be exported at 2x/3x resolution, keeping branding in the artwork.
/// * Folding layers are drawn in their CLOSED positions. Their transformations
///   expose/unfold them at the beginning. The pizza lid has its rear hinge at
///   [lidPivot], normalized within the lid's own rectangle; its closed artwork
///   must completely cover the product. The base must not include a baked lid.
/// * `base`/`rear` sit behind the food and `front` occludes its lower edge. A
///   burger needs separate bottom, left, right and final paper folds. Lavash
///   needs a sleeve and final fold; hot dog needs a tray base and sleeve; fries
///   need carton base/front; a cup needs its separate lid; combo needs bag
///   base/front and a photograph of the selected, already-packed combination.
///
/// This optional artwork overrides the built-in vector packaging only after
/// [isComplete], [matches] and [preload] all succeed. Otherwise the default
/// preset wraps the displayed product image. Resolve option-specific art before
/// constructing this object; the renderer never fabricates food or toppings.
@immutable
class CartPackagingAssets {
  const CartPackagingAssets({
    required this.kind,
    required this.productId,
    required this.layers,
    this.productCutout,
    this.productRect = const Rect.fromLTWH(0.15, 0.23, 0.7, 0.57),
    this.layerRects = const <CartPackagingLayer, Rect>{},
    this.lidPivot = const Offset(0.5, 0),
  });

  final CartPackagingKind kind;
  final String productId;
  final Map<CartPackagingLayer, ImageProvider> layers;
  final ImageProvider? productCutout;
  final Rect productRect;
  final Map<CartPackagingLayer, Rect> layerRects;
  final Offset lidPivot;

  Set<CartPackagingLayer> get requiredLayers => switch (kind) {
    CartPackagingKind.pizza => const {
      CartPackagingLayer.base,
      CartPackagingLayer.front,
      CartPackagingLayer.lid,
    },
    CartPackagingKind.burger => const {
      CartPackagingLayer.base,
      CartPackagingLayer.bottomFold,
      CartPackagingLayer.leftFold,
      CartPackagingLayer.rightFold,
      CartPackagingLayer.finalFold,
    },
    CartPackagingKind.lavash => const {
      CartPackagingLayer.sleeve,
      CartPackagingLayer.finalFold,
    },
    CartPackagingKind.fries => const {
      CartPackagingLayer.base,
      CartPackagingLayer.front,
    },
    CartPackagingKind.hotDog => const {
      CartPackagingLayer.base,
      CartPackagingLayer.sleeve,
    },
    CartPackagingKind.cup => const {CartPackagingLayer.lid},
    CartPackagingKind.combo => const {
      CartPackagingLayer.base,
      CartPackagingLayer.front,
    },
    CartPackagingKind.bottle || CartPackagingKind.none => const {},
  };

  bool get isComplete =>
      kind != CartPackagingKind.none &&
      productId.isNotEmpty &&
      productCutout != null &&
      _validRect(productRect) &&
      layerRects.values.every(_validRect) &&
      lidPivot.dx.isFinite &&
      lidPivot.dy.isFinite &&
      lidPivot.dx >= 0 &&
      lidPivot.dx <= 1 &&
      lidPivot.dy >= 0 &&
      lidPivot.dy <= 1 &&
      requiredLayers.every(layers.containsKey);

  bool matches(MenuProduct product) =>
      isComplete &&
      product.id == productId &&
      classifyCartPackaging(product) == kind;

  /// Uses Flutter's image cache, so lightweight layers are decoded once and
  /// reused. Failures return false instead of showing a partially packed item.
  /// Run before inserting the overlay, never during an animation frame.
  Future<bool> preload(BuildContext context) async {
    if (!isComplete || !context.mounted) return false;
    final providers = <ImageProvider>{...layers.values, productCutout!};
    final results = await Future.wait(
      providers.map((provider) async {
        var loaded = true;
        try {
          await precacheImage(
            provider,
            context,
            onError: (Object _, StackTrace? _) => loaded = false,
          );
        } catch (_) {
          loaded = false;
        }
        return loaded;
      }),
    );
    return results.every((loaded) => loaded);
  }

  static bool _validRect(Rect rect) =>
      rect.isFinite &&
      !rect.isEmpty &&
      rect.left >= 0 &&
      rect.top >= 0 &&
      rect.right <= 1 &&
      rect.bottom <= 1;
}

/// One composited package, driven by normalized preparation progress.
///
/// The owning overlay handles the final flight and cart confirmation.
/// This widget reads no RenderBoxes, starts no timers and owns no cart state.
/// All folding is a paint transform on predetermined normalized rectangles.
class CartPackagingVisual extends StatelessWidget {
  const CartPackagingVisual({
    super.key,
    required this.kind,
    required this.assets,
    required this.product,
    required this.progress,
    required this.size,
  });

  final CartPackagingKind kind;
  final CartPackagingAssets assets;
  final Widget product;
  final double progress;
  final Size size;

  double get _t => progress.clamp(0.0, 1.0);

  double _phase(
    double start,
    double end, [
    Curve curve = Curves.easeInOutCubic,
  ]) => curve.transform(((_t - start) / (end - start)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    if (!assets.isComplete || kind != assets.kind) {
      return SizedBox.fromSize(size: size, child: product);
    }
    final layers = switch (kind) {
      CartPackagingKind.pizza => _pizza(),
      CartPackagingKind.burger => _burger(),
      CartPackagingKind.lavash => _lavash(),
      CartPackagingKind.fries => _fries(),
      CartPackagingKind.hotDog => _hotDog(),
      CartPackagingKind.cup => _cup(),
      CartPackagingKind.combo => _combo(),
      CartPackagingKind.bottle ||
      CartPackagingKind.none => <Widget>[Positioned.fill(child: product)],
    };
    return RepaintBoundary(
      child: SizedBox.fromSize(
        size: size,
        child: Stack(clipBehavior: Clip.none, children: layers),
      ),
    );
  }

  List<Widget> _pizza() {
    final arrive = _phase(0, 0.45, Curves.easeOutCubic);
    final close = _phase(0.45, 0.93);
    final settle = math.sin(_phase(0.93, 1) * math.pi) * 0.012;
    return [
      _layer(CartPackagingLayer.rear, opacity: arrive),
      _layer(CartPackagingLayer.base, opacity: arrive),
      _food(arrive, lift: 0.075),
      _layer(CartPackagingLayer.front, opacity: arrive),
      _layer(
        CartPackagingLayer.lid,
        opacity: arrive,
        alignment: Alignment(
          assets.lidPivot.dx * 2 - 1,
          assets.lidPivot.dy * 2 - 1,
        ),
        transform: _perspective()..rotateX(-1.48 * (1 - close) + settle),
      ),
    ];
  }

  List<Widget> _burger() {
    final arrive = _phase(0, 0.28, Curves.easeOutCubic);
    return [
      _layer(CartPackagingLayer.base, opacity: arrive),
      _food(arrive, lift: 0.04),
      _fold(CartPackagingLayer.bottomFold, 0.22, 0.51, Alignment.bottomCenter),
      _fold(CartPackagingLayer.leftFold, 0.38, 0.69, Alignment.centerLeft),
      _fold(CartPackagingLayer.rightFold, 0.48, 0.78, Alignment.centerRight),
      _fold(CartPackagingLayer.finalFold, 0.7, 0.97, Alignment.topCenter),
    ];
  }

  List<Widget> _lavash() {
    final arrive = _phase(0, 0.35, Curves.easeOutCubic);
    final sleeve = _phase(0.12, 0.72);
    return [
      _layer(CartPackagingLayer.rear, opacity: arrive),
      _food(arrive, lift: 0.025),
      _layer(
        CartPackagingLayer.sleeve,
        opacity: _phase(0.05, 0.2),
        offset: Offset(0, (1 - sleeve) * 0.38),
      ),
      _fold(CartPackagingLayer.finalFold, 0.66, 0.98, Alignment.bottomCenter),
    ];
  }

  List<Widget> _fries() {
    final arrive = _phase(0, 0.72, Curves.easeOutCubic);
    return [
      _layer(CartPackagingLayer.base, opacity: _phase(0, 0.3)),
      _food(arrive, lift: 0.09),
      _layer(CartPackagingLayer.front, opacity: _phase(0.1, 0.45)),
    ];
  }

  List<Widget> _hotDog() {
    final arrive = _phase(0, 0.5, Curves.easeOutCubic);
    final sleeve = _phase(0.4, 0.94);
    return [
      _layer(
        CartPackagingLayer.base,
        opacity: _phase(0, 0.24),
        offset: Offset(0, 0.14 * (1 - arrive)),
      ),
      _food(arrive, lift: 0.035),
      _layer(CartPackagingLayer.front, opacity: arrive),
      _layer(
        CartPackagingLayer.sleeve,
        opacity: _phase(0.35, 0.55),
        offset: Offset(0.35 * (1 - sleeve), 0),
      ),
    ];
  }

  List<Widget> _cup() {
    final arrive = _phase(0, 0.35, Curves.easeOutCubic);
    final close = _phase(0.25, 0.82);
    final snap = math.sin(_phase(0.82, 1) * math.pi) * 0.012;
    return [
      _food(arrive),
      _layer(
        CartPackagingLayer.lid,
        opacity: _phase(0.15, 0.3),
        offset: Offset(0, -0.18 * (1 - close) + snap),
      ),
    ];
  }

  List<Widget> _combo() {
    final arrive = _phase(0, 0.8, Curves.easeOutCubic);
    final bag = _phase(0, 0.28);
    final settle = math.sin(_phase(0.8, 1) * math.pi) * 0.015;
    return [
      _layer(CartPackagingLayer.base, opacity: bag, offset: Offset(0, settle)),
      // This is the actual combination's photo, never invented component food.
      _food(arrive, lift: 0.09),
      _layer(
        CartPackagingLayer.front,
        opacity: _phase(0.12, 0.4),
        offset: Offset(0, settle),
      ),
    ];
  }

  Widget _food(double progress, {double lift = 0}) {
    final rect = assets.productRect;
    final scale = 1 + (math.min(rect.width, rect.height) - 1) * progress;
    final liftOffset = -math.sin(progress * math.pi) * lift;
    return Positioned.fill(
      child: Transform.translate(
        offset: Offset(
          (rect.center.dx - 0.5) * size.width * progress,
          ((rect.center.dy - 0.5) * progress + liftOffset) * size.height,
        ),
        child: Transform.scale(
          scale: scale,
          child: RepaintBoundary(child: product),
        ),
      ),
    );
  }

  Widget _fold(
    CartPackagingLayer layer,
    double start,
    double end,
    Alignment pivot,
  ) {
    final fold = _phase(start, end);
    final transform = _perspective();
    if (pivot.x == 0) {
      transform.rotateX(pivot.y * 1.68 * (1 - fold));
    } else {
      transform.rotateY(-pivot.x * 1.68 * (1 - fold));
    }
    return _layer(
      layer,
      opacity: _phase(math.max(0, start - 0.16), start + 0.08),
      alignment: pivot,
      transform: transform,
    );
  }

  Widget _layer(
    CartPackagingLayer layer, {
    double opacity = 1,
    Offset offset = Offset.zero,
    Alignment alignment = Alignment.center,
    Matrix4? transform,
  }) {
    final provider = assets.layers[layer];
    if (provider == null) return const SizedBox.shrink();
    final rect = assets.layerRects[layer] ?? const Rect.fromLTWH(0, 0, 1, 1);
    Widget image = RepaintBoundary(
      child: Image(
        image: provider,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
    if (transform != null) {
      image = Transform(
        alignment: alignment,
        transform: transform,
        child: image,
      );
    }
    return Positioned.fromRect(
      rect: _pixels(rect),
      child: Transform.translate(
        offset: Offset(offset.dx * size.width, offset.dy * size.height),
        child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: image),
      ),
    );
  }

  Rect _pixels(Rect rect) => Rect.fromLTWH(
    rect.left * size.width,
    rect.top * size.height,
    rect.width * size.width,
    rect.height * size.height,
  );

  Matrix4 _perspective() => Matrix4.identity()..setEntry(3, 2, 0.0014);
}
