import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/app_bottom_sheet_drag_handle.dart';
import 'package:enjoy_lavash_mobile/widgets/app_modal_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/widgets/button.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AppCalendarBottomSheet extends StatefulWidget {
  final DateTime? initialDate;

  const AppCalendarBottomSheet({super.key, this.initialDate});

  /// Static helper method to open the bottom sheet
  static Future<DateTime?> show(BuildContext context, {DateTime? initialDate}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showAppModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? BaseColors.black600 : BaseColors.white,
      enableDrag: true,
      isDismissible: true,
      showDragHandle: false,
      builder: (_) => AppCalendarBottomSheet(initialDate: initialDate),
    );
  }

  @override
  State<AppCalendarBottomSheet> createState() => _AppCalendarBottomSheetState();
}

class _AppCalendarBottomSheetState extends State<AppCalendarBottomSheet> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate ?? DateTime.now();
    _selectedDay = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBottomSheetDragHandle(
            margin: const EdgeInsets.only(bottom: 16),
            color: theme.dividerColor,
          ),

          /// Calendar
          TableCalendar(
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },

            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),

            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleTextStyle: theme.textTheme.titleMedium!,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: MainButton(
              variant: ButtonVariant.primary,
              onPressed: () {
                Navigator.pop(context, _selectedDay);
              },
              title: TypographyText(L.of(context).confirm),
            ),
          ),
        ],
      ),
    );
  }
}
