import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:enjoy_lavash_mobile/widgets/utils/cached_image_provider.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.product,
    this.width = 96,
    this.height = 96,
    this.borderRadius = 24,
    this.fallbackFontSize = 50,
    this.layoutWidth,
    this.placeholderBox,
  });

  final MenuProduct product;
  final double width;
  final double height;
  final double borderRadius;
  final double fallbackFontSize;

  /// The box's real width when [width] is unbounded, for example the menu
  /// grid's column width. Without it the image measures itself.
  final double? layoutWidth;

  /// Box of a smaller copy of this photo that is likely decoded already (the
  /// menu card when its detail page opens). It is shown until this image's
  /// own, larger decode is ready, instead of an empty frame.
  final Size? placeholderBox;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl?.trim();
    final placeholder = Center(
      child: TypographyText(
        product.emoji,
        style: TextStyle(fontSize: fallbackFontSize),
      ),
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[product.highlight, product.tint],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null || imageUrl.isEmpty
          ? placeholder
          : _photo(context, imageUrl, placeholder),
    );
  }

  Widget _photo(BuildContext context, String url, Widget placeholder) {
    final boxWidth = width.isFinite ? width : layoutWidth;
    if (boxWidth != null) {
      return _image(context, url, Size(boxWidth, height), placeholder);
    }
    return LayoutBuilder(
      builder: (context, constraints) =>
          _image(context, url, Size(constraints.maxWidth, height), placeholder),
    );
  }

  Widget _image(
    BuildContext context,
    String url,
    Size box,
    Widget placeholder,
  ) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final smallerBox = placeholderBox;
    return Image(
      // Decoded to cover the box at screen resolution: never squashed, and
      // never narrower than the box (which BoxFit.cover would stretch).
      image: coverNetworkImage(
        url,
        box: box,
        devicePixelRatio: devicePixelRatio,
      ),
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      semanticLabel: product.title,
      errorBuilder: (_, _, _) => placeholder,
      frameBuilder: smallerBox == null
          ? null
          : (context, child, frame, _) {
              if (frame != null) return child;
              return Image(
                image: coverNetworkImage(
                  url,
                  box: smallerBox,
                  devicePixelRatio: devicePixelRatio,
                ),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => const SizedBox.expand(),
              );
            },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder;
      },
    );
  }
}
