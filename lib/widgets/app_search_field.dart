import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// Rounded search box: a search icon, the text and a clear button that
/// appears once something is typed. The border takes the action color while
/// the field has focus. Tapping outside it closes the keyboard; the clear
/// button counts as inside, so clearing keeps the keyboard up.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.clearTooltip,
    required this.onChanged,
    required this.onClear,
  });

  static const double height = 50;
  static const double _iconSize = 22;
  static const double _borderWidth = 1.5;
  static const double _clearDotSize = 24;

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final String clearTooltip;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.duration(context, AppMotion.micro);

    return TextFieldTapRegion(
      child: ListenableBuilder(
        listenable: focusNode,
        builder: (context, child) {
          final focused = focusNode.hasFocus;
          return AnimatedContainer(
            duration: duration,
            curve: AppMotion.standard,
            height: height,
            decoration: BoxDecoration(
              color: AppDesignTokens.surface(context),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
              border: Border.all(
                color: focused
                    ? AppDesignTokens.action
                    : AppDesignTokens.hairline(context),
                width: _borderWidth,
              ),
              boxShadow: AppDesignTokens.cardShadow(context),
            ),
            child: Row(
              children: <Widget>[
                const SizedBox(width: 16),
                Icon(
                  Icons.search_rounded,
                  size: _iconSize,
                  color: focused
                      ? AppDesignTokens.primaryText(context)
                      : AppDesignTokens.secondaryText(context),
                ),
                const SizedBox(width: 10),
                Expanded(child: child!),
                _buildClearButton(context, duration),
              ],
            ),
          );
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onSubmitted: (_) => focusNode.unfocus(),
          onTapOutside: (_) => focusNode.unfocus(),
          textInputAction: TextInputAction.search,
          autocorrect: false,
          cursorColor: AppDesignTokens.action,
          style: AppTextStyles.ui(
            size: 15,
            weight: FontWeight.w500,
            color: AppDesignTokens.primaryText(context),
          ),
          // Every border is set: the app's input theme would otherwise draw
          // its own outline inside this box.
          decoration: InputDecoration(
            isCollapsed: true,
            filled: false,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            hintText: hintText,
            hintStyle: AppTextStyles.ui(
              size: 15,
              color: AppDesignTokens.tertiaryText(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton(BuildContext context, Duration duration) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => AnimatedSwitcher(
        duration: duration,
        switchInCurve: AppMotion.enter,
        switchOutCurve: AppMotion.exit,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: value.text.isEmpty
            ? const SizedBox(width: 12)
            : IconButton(
                key: const ValueKey<String>('app-search-field-clear'),
                tooltip: clearTooltip,
                onPressed: onClear,
                icon: Container(
                  width: _clearDotSize,
                  height: _clearDotSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppDesignTokens.inset(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppDesignTokens.secondaryText(context),
                  ),
                ),
              ),
      ),
    );
  }
}
