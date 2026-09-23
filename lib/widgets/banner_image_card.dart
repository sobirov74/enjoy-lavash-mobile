import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

class BannerImageCard extends StatelessWidget {
  const BannerImageCard({
    super.key,
    required this.title,
    required this.imageUrl,
    this.onTap,
  });

  final String title;
  final String imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF6E4E36),
      borderRadius: BorderRadius.circular(AppDesignTokens.radiusHero),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => const Center(
                child: Icon(Icons.image_outlined, color: Colors.white54),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xD9000000)],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.display(
                        size: 20,
                        height: 1.15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
