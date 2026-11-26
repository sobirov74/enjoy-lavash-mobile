import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:enjoy_lavash_mobile/widgets/utils/cached_image_provider.dart';
import 'package:flutter/material.dart';

Future<void> showOrderReviewPhoto(BuildContext context, String url) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      transitionDuration: AppMotion.duration(context, AppMotion.state),
      reverseTransitionDuration: AppMotion.duration(context, AppMotion.state),
      pageBuilder: (_, _, _) => _OrderReviewPhotoViewer(url: url),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _OrderReviewPhotoViewer extends StatelessWidget {
  const _OrderReviewPhotoViewer({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignTokens.ground(context),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                child: Center(
                  child: Image(
                    image: coverNetworkImage(
                      url,
                      box: MediaQuery.sizeOf(context),
                      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
                    ),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: IconButton.filled(
                key: const ValueKey<String>('review-viewer-close'),
                tooltip: L.of(context).close,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
