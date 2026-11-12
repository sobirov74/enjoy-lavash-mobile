part of 'package:enjoy_lavash_mobile/screens/menu_screen.dart';

class _PartialCartAddition implements Exception {
  const _PartialCartAddition(this.remaining);
  final CartSelection remaining;
}

class _MenuSkeletonCard extends StatelessWidget {
  const _MenuSkeletonCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark
        ? const Color(0xFF1D1A18)
        : const Color(0xFFFFFFFF);
    final highlightColor = isDark
        ? const Color(0xFF302A26)
        : const Color(0xFFF0E8E1);

    return Container(
      height: 118,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              color: highlightColor,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FractionallySizedBox(
                  widthFactor: 0.84,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FractionallySizedBox(
                  widthFactor: 0.52,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FractionallySizedBox(
                  widthFactor: 0.66,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _CategoryHeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}
