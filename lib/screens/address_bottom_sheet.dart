import 'dart:async';

import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:enjoy_lavash_mobile/screens/map_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> showAddressBottomSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<LocationController>(),
      child: const _AddressSheet(),
    ),
  );
}

class _AddressSheet extends StatefulWidget {
  const _AddressSheet();

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _houseController = TextEditingController();
  final _entranceController = TextEditingController();
  final _floorController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _commentController = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  final _geocoderService = YandexGeocoderService();
  final Map<String, List<SuggestionResult>> _suggestionCache =
      <String, List<SuggestionResult>>{};
  List<SuggestionResult> _suggestions = [];
  Timer? _debounce;
  bool _showSearch = false;
  int _searchRequestId = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();

    final loc = context.read<LocationController>();
    _houseController.text = loc.houseNumber;
    _entranceController.text = loc.entrance;
    _floorController.text = loc.floor;
    _apartmentController.text = loc.apartment;
    _commentController.text = loc.comment;
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    _houseController.dispose();
    _entranceController.dispose();
    _floorController.dispose();
    _apartmentController.dispose();
    _commentController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final normalizedQuery = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    final requestId = ++_searchRequestId;
    _debounce?.cancel();

    if (normalizedQuery.length < 3) {
      setState(() => _suggestions = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final cacheKey = normalizedQuery.toLowerCase();
      final cached = _suggestionCache[cacheKey];
      if (cached != null) {
        if (mounted && requestId == _searchRequestId) {
          setState(() => _suggestions = cached);
        }
        return;
      }

      final results = await _geocoderService.suggest(normalizedQuery);
      _suggestionCache[cacheKey] = results;
      if (!mounted ||
          requestId != _searchRequestId ||
          _searchController.text.trim().replaceAll(RegExp(r'\s+'), ' ') !=
              normalizedQuery) {
        return;
      }

      setState(() => _suggestions = results);
    });
  }

  void _selectSuggestion(SuggestionResult suggestion) {
    final loc = context.read<LocationController>();
    loc.setAddressFromSuggestion(suggestion);
    setState(() {
      _showSearch = false;
      _suggestions = [];
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = L.of(context);
    final loc = context.watch<LocationController>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(_fadeAnim),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          margin: EdgeInsets.only(bottom: bottomInset),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1D1A18) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3A3530)
                      : const Color(0xFFE0DBD5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TypographyText(
                        t.deliveryAddress,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2522)
                              : const Color(0xFFF3F0EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current address display
                      _AnimatedAddressCard(
                        isDark: isDark,
                        addressName: loc.addressName,
                        district: loc.district,
                        isLoading: loc.status == LocationStatus.loading,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: context.read<LocationController>(),
                                child: const MapPickerScreen(),
                              ),
                            ),
                          );
                        },
                        onLocate: () => loc.requestPermissionAndLocate(),
                      ),
                      const SizedBox(height: 12),

                      // Search section
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: _showSearch
                            ? Column(
                                children: [
                                  _SearchField(
                                    controller: _searchController,
                                    isDark: isDark,
                                    hint: t.searchAddress,
                                    onChanged: _onSearchChanged,
                                  ),
                                  if (_suggestions.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    _SuggestionsList(
                                      suggestions: _suggestions,
                                      isDark: isDark,
                                      onSelect: _selectSuggestion,
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),

                      // House number (required)
                      TypographyText(
                        t.houseNumber,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : BaseColors.textGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _StyledTextField(
                        controller: _houseController,
                        isDark: isDark,
                        hint: t.houseNumberHint,
                        onChanged: loc.setHouseNumber,
                      ),
                      const SizedBox(height: 16),

                      // Extra fields row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TypographyText(
                                  t.entranceLabel,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white70
                                        : BaseColors.textGray,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _StyledTextField(
                                  controller: _entranceController,
                                  isDark: isDark,
                                  hint: '1',
                                  onChanged: loc.setEntrance,
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TypographyText(
                                  t.floorLabel,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white70
                                        : BaseColors.textGray,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _StyledTextField(
                                  controller: _floorController,
                                  isDark: isDark,
                                  hint: '2',
                                  onChanged: loc.setFloor,
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TypographyText(
                                  t.apartmentLabel,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white70
                                        : BaseColors.textGray,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _StyledTextField(
                                  controller: _apartmentController,
                                  isDark: isDark,
                                  hint: '12',
                                  onChanged: loc.setApartment,
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Comment
                      TypographyText(
                        t.commentLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : BaseColors.textGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _StyledTextField(
                        controller: _commentController,
                        isDark: isDark,
                        hint: t.commentHint,
                        onChanged: loc.setComment,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),

                      // Confirm button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loc.addressName.isNotEmpty
                              ? () => Navigator.pop(context)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BaseColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: isDark
                                ? const Color(0xFF2A2522)
                                : const Color(0xFFE0DBD5),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
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
        ),
      ),
    );
  }
}

// -- Animated address card with pulse effect while loading
class _AnimatedAddressCard extends StatefulWidget {
  const _AnimatedAddressCard({
    required this.isDark,
    required this.addressName,
    required this.district,
    required this.isLoading,
    required this.onTap,
    required this.onLocate,
  });

  final bool isDark;
  final String addressName;
  final String district;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onLocate;

  @override
  State<_AnimatedAddressCard> createState() => _AnimatedAddressCardState();
}

class _AnimatedAddressCardState extends State<_AnimatedAddressCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isLoading) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_AnimatedAddressCard old) {
    super.didUpdateWidget(old);
    if (widget.isLoading && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isLoading && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (_, child) {
          final opacity = widget.isLoading
              ? 0.5 + 0.5 * _pulseController.value
              : 1.0;
          return Opacity(opacity: opacity, child: child);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [BaseColors.primary, Color(0xFFFF7043)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: widget.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TypographyText(
                      widget.addressName.isNotEmpty
                          ? widget.addressName
                          : t.tapToSelectAddress,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.district.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      TypographyText(
                        widget.district,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.isLoading ? null : widget.onLocate,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: widget.isLoading
                        ? const SizedBox(
                            key: ValueKey('locating-loader'),
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            key: ValueKey('locating-icon'),
                            Icons.my_location_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.isDark,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isDark;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF14110F)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF9E9790) : BaseColors.textGray,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: isDark ? const Color(0xFF9E9790) : BaseColors.textGray,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2522) : const Color(0xFFF3F0EB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  const _SuggestionsList({
    required this.suggestions,
    required this.isDark,
    required this.onSelect,
  });

  final List<SuggestionResult> suggestions;
  final bool isDark;
  final ValueChanged<SuggestionResult> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2522) : const Color(0xFFF8F4EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        shrinkWrap: true,
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: isDark ? const Color(0xFF3A3530) : const Color(0xFFE0DBD5),
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final item = suggestions[index];
          return InkWell(
            onTap: () => onSelect(item),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 20,
                    color: BaseColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TypographyText(
                          item.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          TypographyText(
                            item.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF9E9790)
                                  : BaseColors.textGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.isDark,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final bool isDark;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF14110F),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF9E9790) : BaseColors.textGray,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2522) : const Color(0xFFF3F0EB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
