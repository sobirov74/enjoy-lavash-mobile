import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/features/push_permission/push_reminder_schedule.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/widgets/app_bottom_sheet_drag_handle.dart';
import 'package:enjoy_lavash_mobile/widgets/app_modal_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Right after sign-in: the OS prompt if this install never saw it, else
/// the reminder sheet (not limited by the reminder schedule).
Future<void> askForPushNotificationsAfterSignIn(
  BuildContext context, {
  required String locale,
}) async {
  final backend = context.read<MobileBackendController>();
  if (await backend.requestFirstPushNotificationPrompt(locale: locale)) return;
  if (!context.mounted) return;
  await showPushPermissionReminder(
    context,
    locale: locale,
    ignoreSchedule: true,
  );
}

/// Shows the notification reminder when one applies (see
/// [MobileBackendController.takePushPermissionReminder]) and, when the
/// customer accepts, shows the OS prompt or opens the phone settings.
Future<void> showPushPermissionReminder(
  BuildContext context, {
  String? locale,
  bool ignoreSchedule = false,
}) async {
  final backend = context.read<MobileBackendController>();
  final action = await backend.takePushPermissionReminder(
    ignoreSchedule: ignoreSchedule,
  );
  if (action == null || !context.mounted) return;
  final accepted = await showAppModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PushPermissionSheet(action: action),
  );
  if (accepted != true) return;
  await backend.acceptPushPermissionReminder(action, locale: locale);
}

/// Explains what notifications bring and offers to turn them on: through
/// the OS prompt while it can still be shown, else through the phone
/// settings. Pops `true` when the customer accepts.
class PushPermissionSheet extends StatelessWidget {
  const PushPermissionSheet({required this.action, super.key});

  final PushReminderAction action;

  static const double _iconBoxSize = 64;
  static const double _iconSize = 32;

  /// The light `actionSoft` wash glares on a dark sheet; a tint of the
  /// action colour sits back instead.
  static const double _darkIconWash = 0.22;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final opensSettings = action == PushReminderAction.openSettings;
    final secondaryText = AppDesignTokens.secondaryText(context);

    return Container(
      key: const ValueKey<String>('push-permission-sheet'),
      decoration: BoxDecoration(
        color: AppDesignTokens.surface(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDesignTokens.radiusSheet),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppDesignTokens.gutter,
        10,
        AppDesignTokens.gutter,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const AppBottomSheetDragHandle(),
          const SizedBox(height: 18),
          Container(
            width: _iconBoxSize,
            height: _iconBoxSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark
                  ? AppDesignTokens.action.withValues(alpha: _darkIconWash)
                  : AppDesignTokens.actionSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: BaseColors.primary,
              size: _iconSize,
            ),
          ),
          const SizedBox(height: 16),
          TypographyText(
            t.pushReminderTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          TypographyText(
            t.pushReminderBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (opensSettings) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppDesignTokens.inset(context),
                borderRadius: BorderRadius.circular(
                  AppDesignTokens.radiusInput,
                ),
              ),
              child: TypographyText(
                t.pushReminderSettingsHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          FilledButton(
            key: const ValueKey<String>('push-permission-accept'),
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(
                AppDesignTokens.primaryButtonHeight,
              ),
              backgroundColor: AppDesignTokens.action,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: TypographyText(
              opensSettings ? t.pushReminderOpenSettings : t.pushReminderAllow,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            key: const ValueKey<String>('push-permission-later'),
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(AppDesignTokens.buttonHeight),
              foregroundColor: secondaryText,
            ),
            child: TypographyText(
              t.pushReminderLater,
              style: TextStyle(
                color: secondaryText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
