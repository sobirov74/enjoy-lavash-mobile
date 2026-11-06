import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

/// Round notification-inbox button with an unread dot.
///
/// Shared by the home and profile headers so both tabs open the same inbox
/// with the same look.
class NotificationButton extends StatelessWidget {
  const NotificationButton({
    super.key,
    required this.unreadCount,
    required this.label,
    required this.onTap,
  });

  final int unreadCount;
  final String label;
  final VoidCallback onTap;

  static const double _size = 46;
  static const double _iconSize = 22;
  static const double _dotSize = 9;
  static const double _dotInset = 9;
  static const double _dotBorderWidth = 1.5;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: AppDesignTokens.surface(context),
              shape: BoxShape.circle,
              boxShadow: AppDesignTokens.cardShadow(context),
            ),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Icon(
                    Icons.notifications_none_rounded,
                    size: _iconSize,
                    color: AppDesignTokens.primaryText(context),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: _dotInset,
                      right: _dotInset,
                      child: Container(
                        width: _dotSize,
                        height: _dotSize,
                        decoration: BoxDecoration(
                          color: AppDesignTokens.action,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppDesignTokens.surface(context),
                            width: _dotBorderWidth,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
