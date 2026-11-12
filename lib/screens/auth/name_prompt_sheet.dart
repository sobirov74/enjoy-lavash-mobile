part of 'package:enjoy_lavash_mobile/screens/authorization_screen.dart';

class _NamePromptSheet extends StatefulWidget {
  const _NamePromptSheet({required this.initialName});

  final String initialName;

  @override
  State<_NamePromptSheet> createState() => _NamePromptSheetState();
}

class _NamePromptSheetState extends State<_NamePromptSheet> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName.trim();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_isSaving) return;

    final fullName = _nameController.text.trim();
    if (fullName.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final result = await context.read<MobileBackendController>().updateProfile(
      ClientProfileUpdate(fullName: fullName),
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

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
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
                color: isDark
                    ? const Color(0xFF3A332D)
                    : const Color(0xFFE8DED4),
              ),
              TypographyText(
                t.nameOptional,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                enabled: !_isSaving,
                onSubmitted: (_) => _saveName(),
                decoration: InputDecoration(
                  labelText: t.nameOptional,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  filled: true,
                  fillColor: AppDesignTokens.surface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: BaseColors.primary),
                  ),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                TypographyText(
                  _errorText!,
                  style: const TextStyle(
                    color: BaseColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: BaseColors.textGray,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: TypographyText(t.skip),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: BaseColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isSaving ? null : _saveName,
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
      ),
    );
  }
}
