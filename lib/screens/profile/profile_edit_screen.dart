part of '../profile.dart';

class _ProfileEditScreen extends StatefulWidget {
  const _ProfileEditScreen({required this.onDeleteAccount});

  final Future<void> Function() onDeleteAccount;

  @override
  State<_ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<_ProfileEditScreen> {
  late final TextEditingController _nameController;
  DateTime? _birthDate;
  bool _marketingConsent = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final client = context.read<MobileBackendController>().client;
    _nameController = TextEditingController(text: client?.fullName ?? '');
    _birthDate = client?.birthDate;
    _marketingConsent = client?.marketingConsent ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 1, now.month, now.day),
    );
    if (selected != null && mounted) setState(() => _birthDate = selected);
  }

  Future<void> _save() async {
    if (_saving) return;
    final t = L.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(appSnackBar(t.profileName));
      return;
    }

    setState(() => _saving = true);
    final result = await context.read<MobileBackendController>().updateProfile(
      ClientProfileUpdate(
        fullName: name,
        birthDate: _birthDate,
        marketingConsent: _marketingConsent,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);

    switch (result) {
      case Success():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(appSnackBar(t.profileUpdated));
        Navigator.of(context).pop();
      case Error(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          appSnackBar(
            failure.message.trim().isNotEmpty
                ? failure.message
                : t.profileUpdateFailed,
          ),
        );
    }
  }

  Future<void> _deleteAccount() async {
    await widget.onDeleteAccount();
    if (mounted && !context.read<MobileBackendController>().isAuthenticated) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final client = context.watch<MobileBackendController>().client;
    final dateText = _birthDate == null
        ? t.selectBirthDate
        : DateFormat.yMMMd(
            Localizations.localeOf(context).languageCode,
          ).format(_birthDate!);

    return Scaffold(
      backgroundColor: _ProfilePalette.ground(context),
      appBar: AppBar(
        title: Text(t.editProfile),
        backgroundColor: _ProfilePalette.ground(context),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: <Widget>[
            _ProfileCardShell(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextField(
                      key: const ValueKey<String>('profile-name-field'),
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(labelText: t.profileName),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      initialValue: _formatProfilePhone(
                        client?.phoneNumber ?? '',
                      ),
                      readOnly: true,
                      enableInteractiveSelection: false,
                      decoration: InputDecoration(
                        labelText: t.phoneNumber,
                        suffixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(
                        AppDesignTokens.radiusInput,
                      ),
                      onTap: _pickBirthDate,
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: t.birthDate),
                        child: Row(
                          children: <Widget>[
                            Expanded(child: Text(dateText)),
                            const Icon(Icons.calendar_today_outlined, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeTrackColor: BaseColors.primary,
                      value: _marketingConsent,
                      onChanged: _saving
                          ? null
                          : (value) =>
                                setState(() => _marketingConsent = value),
                      title: Text(
                        t.marketingOffers,
                        style: AppTextStyles.ui(
                          size: 15,
                          height: 20 / 15,
                          weight: FontWeight.w600,
                          color: _ProfilePalette.primary(context),
                        ),
                      ),
                      subtitle: Text(
                        t.marketingOffersSubtitle,
                        style: AppTextStyles.ui(
                          size: 11.5,
                          height: 15 / 11.5,
                          color: _ProfilePalette.tertiary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              key: const ValueKey<String>('profile-save-button'),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(t.save),
            ),
            const SizedBox(height: 12),
            TextButton(
              key: const ValueKey<String>('profile-delete-row'),
              onPressed: _saving ? null : _deleteAccount,
              style: TextButton.styleFrom(
                foregroundColor: _ProfilePalette.danger(context),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                t.deleteAccount,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
