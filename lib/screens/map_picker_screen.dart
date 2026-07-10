import 'dart:async';

import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final _mapController = MapController();

  LatLng _selectedPosition = const LatLng(41.2995, 69.2401); // Tashkent default
  String _addressText = '';
  String _district = '';
  bool _isLoading = false;
  Timer? _reverseGeocodeDebounce;
  int _lookupSerial = 0;

  @override
  void initState() {
    super.initState();
    final loc = context.read<LocationController>();
    if (loc.latitude != null && loc.longitude != null) {
      _selectedPosition = LatLng(loc.latitude!, loc.longitude!);
    }
    if (loc.addressName.isNotEmpty) {
      _addressText = loc.addressName;
    }
    if (loc.district.isNotEmpty) {
      _district = loc.district;
    }
  }

  @override
  void dispose() {
    _reverseGeocodeDebounce?.cancel();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    final lookupSerial = ++_lookupSerial;
    _reverseGeocodeDebounce?.cancel();

    setState(() {
      _selectedPosition = point;
      _addressText = '';
      _district = '';
      _isLoading = true;
    });

    _reverseGeocodeDebounce = Timer(const Duration(milliseconds: 550), () {
      unawaited(_resolveAddress(point, lookupSerial));
    });
  }

  Future<void> _resolveAddress(LatLng point, int lookupSerial) async {
    final result = await context.read<LocationController>().resolveAddressName(
      latitude: point.latitude,
      longitude: point.longitude,
    );

    if (!mounted || lookupSerial != _lookupSerial) return;

    setState(() {
      _isLoading = false;
      _addressText = result?.name ?? '';
      _district = result?.district ?? '';
    });
  }

  void _confirmSelection() {
    final loc = context.read<LocationController>();
    loc.setFromMap(
      latitude: _selectedPosition.latitude,
      longitude: _selectedPosition.longitude,
      address: _addressText,
      district: _district,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition,
              initialZoom: 16,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.enjoylavash.mobile',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPosition,
                    width: 40,
                    height: 40,
                    rotate: true,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Back button
          Positioned(
            top: topPadding + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1D1A18) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_rounded),
              ),
            ),
          ),
          Positioned(
            top: topPadding + 12,
            left: 72,
            right: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _isLoading
                  ? _MapLookupStatusPill(
                      key: const ValueKey<String>('lookup-status'),
                      isDark: isDark,
                    )
                  : const SizedBox.shrink(
                      key: ValueKey<String>('lookup-status-empty'),
                    ),
            ),
          ),
          // Bottom card
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding + 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1D1A18) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: BaseColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _isLoading
                              ? _AddressLookupLoading(
                                  key: const ValueKey<String>(
                                    'address-loading',
                                  ),
                                  isDark: isDark,
                                )
                              : TypographyText(
                                  key: const ValueKey<String>('address-text'),
                                  _addressText.isNotEmpty
                                      ? _addressText
                                      : t.tapToSelectAddress,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF14110F),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addressText.isNotEmpty
                          ? _confirmSelection
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BaseColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: isDark
                            ? const Color(0xFF2A2522)
                            : const Color(0xFFE0DBD5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: TypographyText(
                        t.confirmAddress,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLookupStatusPill extends StatelessWidget {
  const _MapLookupStatusPill({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF241C17);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1A18) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: BaseColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: TypographyText(
                L.of(context).findingAddress,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressLookupLoading extends StatefulWidget {
  const _AddressLookupLoading({super.key, required this.isDark});

  final bool isDark;

  @override
  State<_AddressLookupLoading> createState() => _AddressLookupLoadingState();
}

class _AddressLookupLoadingState extends State<_AddressLookupLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : const Color(0xFF241C17);
    final mutedColor = widget.isDark
        ? const Color(0xFF9E9790)
        : BaseColors.textGray;
    final trackColor = widget.isDark
        ? const Color(0xFF3A332D)
        : const Color(0xFFEDE2D7);

    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            return Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: BaseColors.primary.withValues(
                  alpha: 0.12 + (_pulse.value * 0.1),
                ),
                shape: BoxShape.circle,
              ),
              child: Transform.scale(
                scale: 0.9 + (_pulse.value * 0.08),
                child: child,
              ),
            );
          },
          child: const Icon(
            Icons.travel_explore_rounded,
            color: BaseColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TypographyText(
                L.of(context).checkingThisLocation,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              TypographyText(
                L.of(context).gettingAddressDetails,
                style: TextStyle(
                  color: mutedColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  color: BaseColors.primary,
                  backgroundColor: trackColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
