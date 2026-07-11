part of 'package:enjoy_lavash_mobile/screens/profile.dart';

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  bool _acknowledged = false;

  Future<void> _deleteAccount(BuildContext context, L t) async {
    final controller = context.read<MobileBackendController>();
    if (controller.accountDeleting) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final locationController = context.read<LocationController>();
    final result = await controller.deleteAccount();

    if (!mounted) return;

    switch (result) {
      case Success():
        locationController.clearPersonalData();
        navigator.pop();
        messenger.showSnackBar(appSnackBar(t.accountDeleted));
      case Error(:final failure):
        messenger.showSnackBar(
          appSnackBar(
            failure.message.isNotEmpty
                ? failure.message
                : t.deleteAccountFailed,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = L.of(context);
    final deleting = context.watch<MobileBackendController>().accountDeleting;
    final danger = isDark ? BaseColors.dangerDark : BaseColors.danger;

    return PopScope(
      canPop: !deleting,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D1A18) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            18,
            10,
            18,
            22 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF4A4038)
                        : const Color(0xFFE5DAD0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: danger.withValues(alpha: isDark ? 0.22 : 0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.delete_forever_rounded,
                      color: danger,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TypographyText(
                          t.deleteAccountQuestion,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TypographyText(
                          t.deleteAccountPermanentWarning,
                          style: TextStyle(
                            color: isDark
                                ? BaseColors.lightTextGray
                                : BaseColors.textGray,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: deleting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2522)
                      : const Color(0xFFF8F4EF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TypographyText(
                      t.deleteAccountItemsTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DeleteImpactRow(
                      icon: Icons.person_outline_rounded,
                      isDark: isDark,
                      text: t.deleteAccountProfilePhone,
                    ),
                    const SizedBox(height: 10),
                    _DeleteImpactRow(
                      icon: Icons.location_on_outlined,
                      isDark: isDark,
                      text: t.deleteAccountSavedAddresses,
                    ),
                    const SizedBox(height: 10),
                    _DeleteImpactRow(
                      icon: Icons.receipt_long_outlined,
                      isDark: isDark,
                      text: t.orderHistory,
                    ),
                    const SizedBox(height: 10),
                    _DeleteImpactRow(
                      icon: Icons.stars_rounded,
                      isDark: isDark,
                      text: t.deleteAccountBonusPoints,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: deleting
                    ? null
                    : () => setState(() => _acknowledged = !_acknowledged),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
                  decoration: BoxDecoration(
                    color: danger.withValues(alpha: isDark ? 0.12 : 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: danger.withValues(
                        alpha: _acknowledged ? 0.55 : 0.25,
                      ),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Checkbox(
                        value: _acknowledged,
                        activeColor: danger,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        onChanged: deleting
                            ? null
                            : (value) => setState(
                                () => _acknowledged = value ?? false,
                              ),
                      ),
                      Expanded(
                        child: TypographyText(
                          t.deleteAccountAcknowledgement,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: danger,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: danger.withValues(alpha: 0.35),
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _acknowledged && !deleting
                      ? () => unawaited(_deleteAccount(context, t))
                      : null,
                  icon: deleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white70,
                          ),
                        )
                      : const Icon(Icons.delete_forever_rounded, size: 20),
                  label: TypographyText(
                    deleting ? t.deleting : t.deleteMyAccount,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: deleting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: TypographyText(
                    t.cancel,
                    style: const TextStyle(fontWeight: FontWeight.w800),
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

class _DeleteImpactRow extends StatelessWidget {
  const _DeleteImpactRow({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  final IconData icon;
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(
          icon,
          size: 20,
          color: isDark ? BaseColors.lightTextGray : BaseColors.textGray,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TypographyText(
            text,
            style: TextStyle(
              color: isDark ? BaseColors.lightTextGray : BaseColors.textGray,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
