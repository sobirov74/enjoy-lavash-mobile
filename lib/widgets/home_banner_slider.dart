import 'package:enjoy_lavash_mobile/core/navigation/app_deep_link.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/banner_model.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/widgets/banner_image_card.dart';
import 'package:enjoy_lavash_mobile/widgets/promo_slider.dart';
import 'package:flutter/material.dart';

class HomeBannerSlider extends StatefulWidget {
  const HomeBannerSlider({
    super.key,
    required this.banners,
    required this.locale,
    required this.onLinkTap,
  });

  final List<BannerModel> banners;
  final String locale;
  final ValueChanged<Uri> onLinkTap;

  @override
  State<HomeBannerSlider> createState() => _HomeBannerSliderState();
}

class _HomeBannerSliderState extends State<HomeBannerSlider> {
  final _controller = PageController();
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(covariant HomeBannerSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex >= widget.banners.length) {
      _selectedIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(0);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  VoidCallback? _onTap(BannerModel banner) {
    if (banner.promotionId != null) {
      final promotion = banner.promotion;
      if (promotion == null) return null;
      return () => showPromotionDetails(
        context,
        promotion: promotion,
        locale: widget.locale,
      );
    }
    final link = supportedBannerLink(banner.linkUrl);
    return link == null ? null : () => widget.onLinkTap(link);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 172,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (index) => setState(() => _selectedIndex = index),
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == widget.banners.length - 1 ? 0 : 10,
                ),
                child: BannerImageCard(
                  key: ValueKey<String>('home-banner-${banner.id}'),
                  title: banner.title,
                  imageUrl: banner.imageUrl!,
                  onTap: _onTap(banner),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < widget.banners.length; index++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _selectedIndex ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppDesignTokens.action.withValues(
                      alpha: index == _selectedIndex ? 1 : 0.24,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
