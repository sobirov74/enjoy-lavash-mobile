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

/// What the customer answered on [PushPermissionSheet].
enum PushPermissionChoice {
  /// Turn notifications on (the OS prompt, or the phone settings).
  accept,

  /// Not now; the reminder comes back on its schedule.
  later,

  /// Stop reminding.
  never,
}

/// Right after sign-in: the OS prompt if this install never saw it, else
/// the reminder sheet, unless the customer was asked a moment ago. Waits
/// for the customer's answers only, never for the network.
Future<void> askForPushNotificationsAfterSignIn(
  BuildContext context, {
  required String locale,
}) async {
  final backend = context.read<MobileBackendController>();
  if (await backend.requestFirstPushNotificationPrompt(locale: locale)) return;
  if (!context.mounted) return;
  await showPushPermissionReminder(context, locale: locale, atSignIn: true);
}

/// Shows the notification reminder when one applies (see
/// [MobileBackendController.takePushPermissionReminder]) and acts on the
/// customer's answer: the OS prompt or the phone settings, nothing, or no
/// more reminders.
Future<void> showPushPermissionReminder(
  BuildContext context, {
  String? locale,
  bool atSignIn = false,
}) async {
  final backend = context.read<MobileBackendController>();
  final action = await backend.takePushPermissionReminder(atSignIn: atSignIn);
  if (action == null || !context.mounted) return;
  final choice = await showAppModalBottomSheet<PushPermissionChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PushPermissionSheet(action: action),
  );
  switch (choice) {
    case PushPermissionChoice.accept:
      await backend.acceptPushPermissionReminder(action, locale: locale);
    case PushPermissionChoice.never:
      await backend.stopPushPermissionReminders();
    case PushPermissionChoice.later || null:
      break;
  }
}

/// Explains what notifications bring and offers to turn them on: through
/// the OS prompt while it can still be shown, else through the phone
/// settings. Pops the customer's [PushPermissionChoice].
class PushPermissionSheet extends StatelessWidget {
  const PushPermissionSheet({required this.action, super.key});

  final PushReminderAction action;

  /// The sheet never covers more of the screen than this; on a short screen
  /// or with large text its content scrolls instead of being cut off.
  static const double _maxHeightFraction = 0.88;
  static const double _iconBoxSize = 64;
  static const double _iconSize = 32;
  static const double _gapSmall = 8;
  static const double _gapMedium = 16;
  static const double _gapLarge = 22;
  static const double _hintPadding = 12;

  /// The smallest comfortable tap target, for the quietest action.
  static const double _minTapHeight = 48;

  /// The light `actionSoft` wash glares on a dark sheet; a tint of the
  /// action colour sits back instead.
  static const double _darkIconWash = 0.22;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final opensSettings = action == PushReminderAction.openSettings;
    final primaryText = AppDesignTokens.primaryText(context);
    final secondaryText = AppDesignTokens.secondaryText(context);

    return Container(
      key: const ValueKey<String>('push-permission-sheet'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * _maxHeightFraction,
      ),
      decoration: BoxDecoration(
        color: AppDesignTokens.surface(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDesignTokens.radiusSheet),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppDesignTokens.gutter,
          _gapSmall,
          AppDesignTokens.gutter,
          _gapSmall + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const AppBottomSheetDragHandle(),
            const SizedBox(height: _gapMedium),
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
            const SizedBox(height: _gapMedium),
            Semantics(
              header: true,
              child: TypographyText(
                t.pushReminderTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: _gapSmall),
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
              const SizedBox(height: _hintPadding),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(_hintPadding),
                decoration: BoxDecoration(
                  color: AppDesignTokens.inset(context),
                  borderRadius: BorderRadius.circular(
                    AppDesignTokens.radiusInput,
                  ),
                ),
                // The steps the customer has to follow: full-strength text.
                child: TypographyText(
                  t.pushReminderSettingsHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
            const SizedBox(height: _gapLarge),
            FilledButton(
              key: const ValueKey<String>('push-permission-accept'),
              onPressed: () =>
                  Navigator.of(context).pop(PushPermissionChoice.accept),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(
                  AppDesignTokens.primaryButtonHeight,
                ),
                backgroundColor: AppDesignTokens.action,
                foregroundColor: BaseColors.white,
                shape: const StadiumBorder(),
              ),
              child: TypographyText(
                opensSettings
                    ? t.pushReminderOpenSettings
                    : t.pushReminderAllow,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: BaseColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: _gapSmall),
            TextButton(
              key: const ValueKey<String>('push-permission-later'),
              onPressed: () =>
                  Navigator.of(context).pop(PushPermissionChoice.later),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(
                  AppDesignTokens.buttonHeight,
                ),
                foregroundColor: secondaryText,
              ),
              child: TypographyText(
                t.pushReminderLater,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              key: const ValueKey<String>('push-permission-never'),
              onPressed: () =>
                  Navigator.of(context).pop(PushPermissionChoice.never),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(_minTapHeight),
                foregroundColor: secondaryText,
              ),
              child: TypographyText(
                t.pushReminderNever,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
