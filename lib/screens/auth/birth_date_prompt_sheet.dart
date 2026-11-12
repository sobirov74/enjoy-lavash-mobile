part of 'package:enjoy_lavash_mobile/screens/authorization_screen.dart';

Future<void> showBirthDatePromptSheet(
  BuildContext context, {
  DateTime? initialDate,
}) {
  return showAppModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    isDismissible: true,
    showDragHandle: false,
    builder: (_) => _BirthDatePromptSheet(initialDate: initialDate),
  );
}

class _BirthDatePromptSheet extends StatefulWidget {
  const _BirthDatePromptSheet({this.initialDate});

  final DateTime? initialDate;

  @override
  State<_BirthDatePromptSheet> createState() => _BirthDatePromptSheetState();
}

class _BirthDatePromptSheetState extends State<_BirthDatePromptSheet> {
  static const int _firstYear = 1900;
  static const double _pickerItemExtent = 44;

  late final List<int> _years;
  late final FixedExtentScrollController _dayController;
  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _yearController;
  late final DateTime _today;
  late DateTime _selectedDate;

  /// The selected date for the parts that show it (date text, screen-reader
  /// value). Scrolling a picker updates only those; the pickers rebuild only
  /// when the number of days or months changes.
  late final ValueNotifier<DateTime> _selectedDateValue =
      ValueNotifier<DateTime>(_selectedDate);
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _years = List<int>.generate(
      _today.year - _firstYear + 1,
      (index) => _today.year - index,
    );
    _selectedDate = _normalizedInitialDate(
      widget.initialDate ?? DateTime(_today.year - 25),
      _today,
    );
    _dayController = FixedExtentScrollController(
      initialItem: _selectedDate.day - 1,
    );
    _monthController = FixedExtentScrollController(
      initialItem: _selectedDate.month - 1,
    );
    _yearController = FixedExtentScrollController(
      initialItem: _today.year - _selectedDate.year,
    );
  }

  @override
  void dispose() {
    _selectedDateValue.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  DateTime _normalizedInitialDate(DateTime date, DateTime now) {
    if (date.isAfter(now)) {
      return DateTime(now.year, now.month, now.day);
    }
    if (date.year < _firstYear) {
      return DateTime(_firstYear, 1, 1);
    }
    return DateTime(date.year, date.month, date.day);
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  int _availableMonths(int year) {
    return year == _today.year ? _today.month : 12;
  }

  int _availableDays(int year, int month) {
    final daysInMonth = _daysInMonth(year, month);
    if (year == _today.year && month == _today.month) {
      return _today.day;
    }
    return daysInMonth;
  }

  void _setSelectedDate({int? day, int? month, int? year}) {
    if (_isSaving) return;

    final nextYear = year ?? _selectedDate.year;
    final requestedMonth = month ?? _selectedDate.month;
    final nextMonth = requestedMonth.clamp(1, _availableMonths(nextYear));
    final requestedDay = day ?? _selectedDate.day;
    final nextDay = requestedDay.clamp(1, _availableDays(nextYear, nextMonth));
    final didClampMonth = nextMonth != requestedMonth;
    final didClampDay = nextDay != requestedDay;

    final next = DateTime(nextYear, nextMonth, nextDay);
    final countsChanged =
        _availableDays(next.year, next.month) !=
            _availableDays(_selectedDate.year, _selectedDate.month) ||
        _availableMonths(next.year) != _availableMonths(_selectedDate.year);
    final clearsError = _errorText != null;
    _selectedDate = next;
    if (countsChanged || clearsError) {
      setState(() => _errorText = null);
    }
    _selectedDateValue.value = next;
    unawaited(HapticFeedback.selectionClick());

    if (didClampMonth || didClampDay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (didClampMonth && _monthController.hasClients) {
          _monthController.jumpToItem(nextMonth - 1);
        }
        if (didClampDay && _dayController.hasClients) {
          _dayController.jumpToItem(nextDay - 1);
        }
      });
    }
  }

  Future<void> _saveBirthDate() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final result = await context.read<MobileBackendController>().updateProfile(
      ClientProfileUpdate(birthDate: _selectedDate),
    );
    if (!mounted) return;

    switch (result) {
      case Success():
        Navigator.of(context).pop();
      case Error(:final failure):
        setState(() {
          _isSaving = false;
          _errorText = failureMessage(L.of(context), failure);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = L.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final primaryText = AppDesignTokens.primaryText(context);
    final secondaryText = AppDesignTokens.tertiaryText(context);
    final accentColor = isDark
        ? BaseColors.primaryOnDark
        : BaseColors.primaryDark;
    final pickerTextStyle = TextStyle(
      color: primaryText,
      fontSize: 19,
      fontWeight: FontWeight.w700,
    );
    final pickerBackground = AppDesignTokens.surface(context);
    final pickerSelectionColor =
        (isDark ? BaseColors.primaryOnDark : BaseColors.primary).withValues(
          alpha: isDark ? 0.20 : 0.12,
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppBottomSheetDragHandle(
              margin: const EdgeInsets.only(bottom: 8),
              color: secondaryText,
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TypographyText(
                    t.birthDateTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey<String>('birth-date-close-button'),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  color: primaryText,
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TypographyText(
              t.birthDateSubtitle,
              style: TextStyle(
                color: secondaryText,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<DateTime>(
              valueListenable: _selectedDateValue,
              builder: (context, date, pickers) => Semantics(
                label: t.birthDate,
                value: dateFormat(
                  locale,
                  'yMMMMd',
                  DateFormat.yMMMMd,
                ).format(date),
                child: pickers,
              ),
              child: Container(
                key: const ValueKey<String>('birth-date-field'),
                height: 210,
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                decoration: BoxDecoration(
                  color: pickerBackground,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppDesignTokens.controlBorder(context),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        _BirthDatePickerLabel(t.birthDateDay),
                        _BirthDatePickerLabel(t.birthDateMonth, flex: 2),
                        _BirthDatePickerLabel(t.birthDateYear),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: CupertinoPicker.builder(
                              key: const ValueKey<String>(
                                'birth-date-day-picker',
                              ),
                              scrollController: _dayController,
                              itemExtent: _pickerItemExtent,
                              useMagnifier: true,
                              magnification: 1.08,
                              selectionOverlay:
                                  CupertinoPickerDefaultSelectionOverlay(
                                    background: pickerSelectionColor,
                                  ),
                              onSelectedItemChanged: (index) =>
                                  _setSelectedDate(day: index + 1),
                              childCount: _availableDays(
                                _selectedDate.year,
                                _selectedDate.month,
                              ),
                              itemBuilder: (_, index) => Center(
                                child: Text(
                                  '${index + 1}',
                                  style: pickerTextStyle,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: CupertinoPicker.builder(
                              key: const ValueKey<String>(
                                'birth-date-month-picker',
                              ),
                              scrollController: _monthController,
                              itemExtent: _pickerItemExtent,
                              useMagnifier: true,
                              magnification: 1.08,
                              selectionOverlay:
                                  CupertinoPickerDefaultSelectionOverlay(
                                    background: pickerSelectionColor,
                                  ),
                              onSelectedItemChanged: (index) =>
                                  _setSelectedDate(month: index + 1),
                              childCount: _availableMonths(_selectedDate.year),
                              itemBuilder: (_, index) => Center(
                                child: Text(
                                  dateFormat(
                                    locale,
                                    'MMM',
                                    DateFormat.MMM,
                                  ).format(DateTime(2000, index + 1)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: pickerTextStyle,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: CupertinoPicker.builder(
                              key: const ValueKey<String>(
                                'birth-date-year-picker',
                              ),
                              scrollController: _yearController,
                              itemExtent: _pickerItemExtent,
                              useMagnifier: true,
                              magnification: 1.08,
                              selectionOverlay:
                                  CupertinoPickerDefaultSelectionOverlay(
                                    background: pickerSelectionColor,
                                  ),
                              onSelectedItemChanged: (index) =>
                                  _setSelectedDate(year: _years[index]),
                              childCount: _years.length,
                              itemBuilder: (_, index) => Center(
                                child: Text(
                                  '${_years[index]}',
                                  style: pickerTextStyle,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? BaseColors.primaryOnDark.withValues(alpha: 0.12)
                    : BaseColors.surfaceTint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.cake_outlined, color: accentColor, size: 21),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TypographyText(
                          t.birthDate,
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        ValueListenableBuilder<DateTime>(
                          valueListenable: _selectedDateValue,
                          builder: (context, date, _) => TypographyText(
                            dateFormat(
                              locale,
                              'yMMMMd',
                              DateFormat.yMMMMd,
                            ).format(date),
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              TypographyText(
                _errorText!,
                style: TextStyle(
                  color: AppDesignTokens.dangerText(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextButton(
                    key: const ValueKey<String>('birth-date-skip-button'),
                    style: TextButton.styleFrom(
                      foregroundColor: secondaryText,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(t.skip),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey<String>('birth-date-save-button'),
                    style: FilledButton.styleFrom(
                      backgroundColor: BaseColors.primaryDark,
                      disabledBackgroundColor: BaseColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isSaving ? null : _saveBirthDate,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : TypographyText(
                            t.save,
                            style: const TextStyle(color: BaseColors.white),
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

class _BirthDatePickerLabel extends StatelessWidget {
  const _BirthDatePickerLabel(this.text, {this.flex = 1});

  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: TypographyText(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppDesignTokens.tertiaryText(context),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
