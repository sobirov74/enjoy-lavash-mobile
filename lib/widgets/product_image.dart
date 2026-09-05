import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.product,
    this.width = 96,
    this.height = 96,
    this.borderRadius = 24,
    this.fallbackFontSize = 50,
  });

  final MenuProduct product;
  final double width;
  final double height;
  final double borderRadius;
  final double fallbackFontSize;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl?.trim();
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = width.isFinite
        ? (width * devicePixelRatio).round()
        : null;
    final cacheHeight = height.isFinite
        ? (height * devicePixelRatio).round()
        : null;
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
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              cacheWidth: cacheWidth,
              cacheHeight: cacheHeight,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              semanticLabel: product.title,
              errorBuilder: (_, _, _) => placeholder,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return placeholder;
              },
            ),
    );
  }
}
