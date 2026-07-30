import 'dart:async';

import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_notification_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/assigned_promotions_screen.dart';
import 'package:enjoy_lavash_mobile/screens/loyalty_wallet_screen.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/animated_error_message.dart';
import 'package:enjoy_lavash_mobile/widgets/app_bottom_sheet_drag_handle.dart';
import 'package:enjoy_lavash_mobile/widgets/app_modal_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/widgets/app_snack_bar.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_refresh());
    });
  }

  Future<void> _refresh() async {
    await context.read<MobileBackendController>().refreshNotifications();
  }

  Future<void> _markAllRead() async {
    final result = await context
        .read<MobileBackendController>()
        .markAllNotificationsRead();
    if (!mounted || result.isSuccess) return;
    _showFailure(result.failureOrNull?.message);
  }

  Future<void> _markUnread(ClientNotificationItemModel notification) async {
    final result = await context
        .read<MobileBackendController>()
        .markNotificationUnread(notificationId: notification.notificationId);
    if (!mounted || result.isSuccess) return;
    _showFailure(result.failureOrNull?.message);
  }

  Future<void> _openNotification(
    ClientNotificationItemModel notification,
  ) async {
    if (!notification.isRead) {
      final result = await context
          .read<MobileBackendController>()
          .markNotificationRead(notificationId: notification.notificationId);
      if (!mounted) return;
      if (result.isError) {
        _showFailure(result.failureOrNull?.message);
      }
    }

    if (notification.opensPromotions) {
      final code = await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          builder: (_) => AssignedPromotionsScreen(
            initialShowAll: true,
            highlightedCode: notification.promotionCode,
          ),
        ),
      );
      if (mounted && code != null) {
        Navigator.of(context).pop(code);
      }
      return;
    }

    if (notification.opensLoyalty) {
      await context.read<MobileBackendController>().refreshLoyaltyWallet();
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const LoyaltyWalletScreen()),
      );
      return;
    }

    await showAppModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      showDragHandle: false,
      builder: (_) => _NotificationDetailsSheet(notification: notification),
    );
  }

  void _showFailure(String? message) {
    final text = message?.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      appSnackBar(
        text?.isNotEmpty == true ? text! : L.of(context).errorGenericBody,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backend = context.watch<MobileBackendController>();
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: TypographyText(
          t.notificationInbox,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          if (backend.notificationUnreadCount > 0)
            IconButton(
              onPressed: backend.notificationsLoading
                  ? null
                  : () => unawaited(_markAllRead()),
              tooltip: t.markAllRead,
              icon: const Icon(Icons.done_all_rounded),
              color: BaseColors.primary,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: BaseColors.primary,
        onRefresh: _refresh,
        child: _buildBody(backend, isDark, t),
      ),
    );
  }

  Widget _buildBody(MobileBackendController backend, bool isDark, L t) {
    if (backend.notificationsLoading && backend.notifications.isEmpty) {
      return const _NotificationLoadingList();
    }

    final failure = backend.notificationsFailure;
    if (failure != null && backend.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 96),
          AnimatedErrorMessage(
            failure: failure,
            onRetry: () => unawaited(_refresh()),
          ),
        ],
      );
    }

    if (backend.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 120, 32, 32),
        children: <Widget>[_EmptyInbox(isDark: isDark)],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      itemCount: backend.notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final notification = backend.notifications[index];
        return _NotificationCard(
          notification: notification,
          isDark: isDark,
          locale: Localizations.localeOf(context).languageCode,
          onTap: () => unawaited(_openNotification(notification)),
          onMarkUnread: notification.isRead
              ? () => unawaited(_markUnread(notification))
              : null,
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.isDark,
    required this.locale,
    required this.onTap,
    required this.onMarkUnread,
  });

  final ClientNotificationItemModel notification;
  final bool isDark;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback? onMarkUnread;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final unread = !notification.isRead;
    final sentAt = notification.sentAt?.toLocal();
    final date = sentAt == null
        ? null
        : DateFormat('d MMM, HH:mm', locale).format(sentAt);
    final surface = unread
        ? BaseColors.primary.withValues(alpha: isDark ? 0.15 : 0.09)
        : (isDark ? const Color(0xFF1D1A18) : Colors.white);

    return Semantics(
      button: true,
      label: '${notification.title}. ${notification.body}',
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: notification.opensPromotions
                        ? const Color(0xFFFFE7A3)
                        : BaseColors.surfaceTint,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    notification.opensPromotions
                        ? Icons.local_offer_rounded
                        : Icons.notifications_rounded,
                    color: BaseColors.primaryDark,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TypographyText(
                              notification.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.15,
                                fontWeight: unread
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                          if (unread) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: BaseColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      TypographyText(
                        notification.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? BaseColors.lightTextGray
                              : BaseColors.textGray,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                      if (date != null) ...[
                        const SizedBox(height: 8),
                        TypographyText(
                          date,
                          style: TextStyle(
                            color: isDark
                                ? BaseColors.lightTextGray
                                : BaseColors.textGray,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onMarkUnread != null)
                  IconButton(
                    onPressed: onMarkUnread,
                    tooltip: t.markUnread,
                    icon: const Icon(Icons.mark_email_unread_outlined),
                    color: BaseColors.primary,
                    iconSize: 21,
                  )
                else
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8, 12, 8, 0),
                    child: Icon(Icons.chevron_right_rounded),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return Column(
      children: <Widget>[
        Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: BaseColors.primary.withValues(alpha: isDark ? 0.18 : 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: BaseColors.primary,
            size: 42,
          ),
        ),
        const SizedBox(height: 22),
        TypographyText(
          t.noNotifications,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        TypographyText(
          t.noNotificationsSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? BaseColors.lightTextGray : BaseColors.textGray,
            fontSize: 15,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _NotificationLoadingList extends StatelessWidget {
  const _NotificationLoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        height: 112,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1D1A18)
              : Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    );
  }
}

class _NotificationDetailsSheet extends StatelessWidget {
  const _NotificationDetailsSheet({required this.notification});

  final ClientNotificationItemModel notification;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sentAt = notification.sentAt?.toLocal();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1A18) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppBottomSheetDragHandle(
            color: isDark ? BaseColors.borderDark : BaseColors.borderLight,
          ),
          const SizedBox(height: 12),
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BaseColors.surfaceTint,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: BaseColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          TypographyText(
            notification.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          TypographyText(
            notification.body,
            style: const TextStyle(fontSize: 16, height: 1.45),
          ),
          if (sentAt != null) ...[
            const SizedBox(height: 16),
            TypographyText(
              DateFormat.yMMMd(
                Localizations.localeOf(context).languageCode,
              ).add_Hm().format(sentAt),
              style: TextStyle(
                color: isDark ? BaseColors.lightTextGray : BaseColors.textGray,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: BaseColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: TypographyText(
                t.close,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
