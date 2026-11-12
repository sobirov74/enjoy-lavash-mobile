part of 'package:enjoy_lavash_mobile/screens/profile.dart';

Future<void> _showProfileLanguageSheet(
  BuildContext context,
  LocaleController controller,
) {
  final t = L.of(context);
  return showAppModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          20 + MediaQuery.paddingOf(sheetContext).bottom,
        ),
        decoration: BoxDecoration(
          color: _ProfilePalette.surface(sheetContext),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDesignTokens.radiusSheet),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const AppBottomSheetDragHandle(),
            const SizedBox(height: 8),
            Text(
              t.language,
              style: AppTextStyles.display(
                size: 21,
                height: 24 / 21,
                color: _ProfilePalette.primary(sheetContext),
              ).copyWith(letterSpacing: 0),
            ),
            const SizedBox(height: 14),
            for (final locale in LocaleController.supportedLocales)
              _ProfileLanguageOption(
                locale: locale,
                selected: controller.locale == locale,
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await controller.setLocale(locale);
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      );
    },
  );
}

class _ProfileLanguageOption extends StatelessWidget {
  const _ProfileLanguageOption({
    required this.locale,
    required this.selected,
    required this.onTap,
  });

  final Locale locale;
  final bool selected;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusInput),
        onTap: () => unawaited(onTap()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _profileLanguageName(locale.languageCode),
                  style: AppTextStyles.ui(
                    size: 15,
                    height: 20 / 15,
                    weight: FontWeight.w600,
                    color: _ProfilePalette.primary(context),
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: BaseColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _profileLanguageName(String code) => switch (code) {
  'ru' => 'Русский',
  'en' => 'English',
  _ => "Özbekça",
};
