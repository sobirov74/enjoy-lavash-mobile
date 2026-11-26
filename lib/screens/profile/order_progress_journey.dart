part of 'package:enjoy_lavash_mobile/screens/profile.dart';

const List<MobileOrderStatus> _deliveryJourneyStages = <MobileOrderStatus>[
  MobileOrderStatus.newOrder,
  MobileOrderStatus.confirmed,
  MobileOrderStatus.cooking,
  MobileOrderStatus.ready,
  MobileOrderStatus.courierAssigned,
  MobileOrderStatus.onTheWay,
  MobileOrderStatus.delivered,
];

const List<MobileOrderStatus> _pickupJourneyStages = <MobileOrderStatus>[
  MobileOrderStatus.newOrder,
  MobileOrderStatus.confirmed,
  MobileOrderStatus.cooking,
  MobileOrderStatus.ready,
  MobileOrderStatus.delivered,
];

List<MobileOrderStatus> _orderJourneyStages(MobileOrderType orderType) {
  return switch (orderType) {
    MobileOrderType.delivery => _deliveryJourneyStages,
    MobileOrderType.pickup => _pickupJourneyStages,
  };
}

bool _supportsOrderJourney(
  MobileOrderType orderType,
  MobileOrderStatus status,
) {
  return _orderJourneyStages(orderType).contains(status);
}

double _orderJourneyProgress(
  MobileOrderType orderType,
  MobileOrderStatus status,
) {
  final stages = _orderJourneyStages(orderType);
  final index = stages.indexOf(status);
  if (index <= 0) return 0;
  return index / (stages.length - 1);
}

/// A quiet, state-driven journey through an order's real lifecycle.
///
/// It starts at the supplied status and only animates when that status changes.
/// There are no timers or repeating effects, so the indicator never implies
/// progress that the server has not reported.
class OrderProgressJourney extends StatefulWidget {
  const OrderProgressJourney({
    super.key,
    required this.orderType,
    required this.status,
  });

  final MobileOrderType orderType;
  final MobileOrderStatus status;

  @override
  State<OrderProgressJourney> createState() => _OrderProgressJourneyState();
}

class _OrderProgressJourneyState extends State<OrderProgressJourney>
    with SingleTickerProviderStateMixin {
  late double _targetProgress;
  late final AnimationController _controller;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _targetProgress = _orderJourneyProgress(widget.orderType, widget.status);
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.spatial,
      value: _targetProgress,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = AppMotion.reduced(context);
    _controller.duration = AppMotion.duration(context, AppMotion.spatial);
    if (_reduceMotion) {
      _controller.value = _targetProgress;
    }
  }

  @override
  void didUpdateWidget(covariant OrderProgressJourney oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderType == widget.orderType &&
        oldWidget.status == widget.status) {
      return;
    }

    final nextProgress = _orderJourneyProgress(widget.orderType, widget.status);
    _targetProgress = nextProgress;
    _controller.stop();

    if (_reduceMotion ||
        !_supportsOrderJourney(widget.orderType, widget.status)) {
      _controller.value = nextProgress;
      return;
    }

    _controller.animateTo(nextProgress, curve: AppMotion.enter);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stages = _orderJourneyStages(widget.orderType);
    final currentIndex = stages.indexOf(widget.status);
    if (currentIndex < 0) return const SizedBox.shrink();

    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = BaseColors.primary;
    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.black.withValues(alpha: 0.12);
    final idleDotColor = isDark
        ? const Color(0xFF665D56)
        : const Color(0xFFD8CEC5);

    return Semantics(
      key: const ValueKey<String>('order-progress-journey'),
      container: true,
      label: '${t.currentStatus}: ${_statusLabel(widget.status, t)}',
      child: ExcludeSemantics(
        child: Column(
          children: <Widget>[
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final journeyPosition = _controller.value * (stages.length - 1);
                return Row(
                  children: <Widget>[
                    for (int index = 0; index < stages.length; index++) ...[
                      _OrderJourneyDot(
                        key: ValueKey<String>('order-progress-dot-$index'),
                        progress: index == 0
                            ? 1
                            : (journeyPosition - (index - 1))
                                  .clamp(0.0, 1.0)
                                  .toDouble(),
                        current: index == currentIndex,
                        accent: accent,
                        idleColor: idleDotColor,
                      ),
                      if (index < stages.length - 1)
                        Expanded(
                          child: _OrderJourneySegment(
                            index: index,
                            progress: (journeyPosition - index)
                                .clamp(0.0, 1.0)
                                .toDouble(),
                            accent: accent,
                            trackColor: trackColor,
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 7),
            Row(
              children: <Widget>[
                Expanded(
                  child: TypographyText(
                    _statusLabel(stages.first, t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFB8AEA5)
                          : BaseColors.textGray,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TypographyText(
                    _statusLabel(stages.last, t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFB8AEA5)
                          : BaseColors.textGray,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderJourneySegment extends StatelessWidget {
  const _OrderJourneySegment({
    required this.index,
    required this.progress,
    required this.accent,
    required this.trackColor,
  });

  final int index;
  final double progress;
  final Color accent;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 3,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ColoredBox(color: trackColor),
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  key: ValueKey<String>('order-progress-segment-$index-fill'),
                  widthFactor: progress,
                  heightFactor: 1,
                  child: ColoredBox(color: accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderJourneyDot extends StatelessWidget {
  const _OrderJourneyDot({
    super.key,
    required this.progress,
    required this.current,
    required this.accent,
    required this.idleColor,
  });

  final double progress;
  final bool current;
  final Color accent;
  final Color idleColor;

  @override
  Widget build(BuildContext context) {
    final fill = Color.lerp(idleColor, accent, progress)!;

    return SizedBox.square(
      dimension: 18,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: current
              ? Border.all(color: accent.withValues(alpha: 0.38), width: 3)
              : null,
        ),
        child: Center(
          child: Container(
            width: current ? 9 : 7,
            height: current ? 9 : 7,
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
