part of '../profile.dart';

class _SavedAddressesScreen extends StatefulWidget {
  const _SavedAddressesScreen();

  @override
  State<_SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<_SavedAddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(context.read<MobileBackendController>().refreshAddresses());
      }
    });
  }

  Future<void> _addAddress() async {
    final confirmed = await showAddressBottomSheet(context);
    if (confirmed != true || !mounted) return;

    final location = context.read<LocationController>();
    final latitude = location.latitude;
    final longitude = location.longitude;
    if (location.addressName.trim().isEmpty ||
        latitude == null ||
        longitude == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(appSnackBar(L.of(context).addressSaveFailed));
      return;
    }

    final details = await _showAddressDetailsSheet(
      context,
      makeDefault: context.read<MobileBackendController>().addresses.isEmpty,
    );
    if (details == null || !mounted) return;

    final t = L.of(context);
    final result = await context.read<MobileBackendController>().createAddress(
      ClientAddressInput(
        label: details.label,
        street: location.addressName.trim(),
        houseNumber: _nullIfEmpty(location.houseNumber),
        apartmentNumber: _nullIfEmpty(location.apartment),
        entrance: _nullIfEmpty(location.entrance),
        floor: _nullIfEmpty(location.floor),
        latitude: latitude,
        longitude: longitude,
        comment: _nullIfEmpty(location.comment),
        isDefault: details.makeDefault,
      ),
    );
    if (!mounted) return;
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(appSnackBar(t.addressSaved));
      case Error(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          appSnackBar(
            failure.message.trim().isNotEmpty
                ? failure.message
                : t.addressSaveFailed,
          ),
        );
    }
  }

  Future<void> _makeDefault(ClientAddress address) async {
    final t = L.of(context);
    final result = await context.read<MobileBackendController>().updateAddress(
      id: address.id,
      request: _addressInput(address, isDefault: true),
    );
    if (!mounted) return;
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(appSnackBar(t.addressSaved));
      case Error(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          appSnackBar(
            failure.message.trim().isNotEmpty
                ? failure.message
                : t.addressSaveFailed,
          ),
        );
    }
  }

  void _confirmDelete(ClientAddress address) {
    final t = L.of(context);
    showConfirmDialog(
      context: context,
      title: t.deleteAddress,
      confirmText: t.deleteAddress,
      cancelText: t.cancel,
      footerReversed: true,
      onCancel: () {},
      onConfirm: () => unawaited(_deleteAddress(address)),
      child: Text(
        _formatSavedAddress(address),
        style: TextStyle(color: _ProfilePalette.secondary(context)),
      ),
    );
  }

  Future<void> _deleteAddress(ClientAddress address) async {
    final t = L.of(context);
    final result = await context.read<MobileBackendController>().deleteAddress(
      id: address.id,
    );
    if (!mounted) return;
    switch (result) {
      case Success():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(appSnackBar(t.addressDeleted));
      case Error(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          appSnackBar(
            failure.message.trim().isNotEmpty
                ? failure.message
                : t.addressDeleteFailed,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final backend = context.watch<MobileBackendController>();
    final addresses = backend.addresses;

    return Scaffold(
      backgroundColor: _ProfilePalette.ground(context),
      appBar: AppBar(
        title: Text(t.savedAddresses),
        backgroundColor: _ProfilePalette.ground(context),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: BaseColors.primary,
          onRefresh: () async {
            await backend.refreshAddresses();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
            children: <Widget>[
              if (backend.addressesFailure != null && addresses.isEmpty)
                AnimatedErrorMessage(
                  failure: backend.addressesFailure!,
                  onRetry: () => unawaited(backend.refreshAddresses()),
                )
              else if (addresses.isEmpty)
                _SavedAddressesEmpty(onAdd: _addAddress)
              else
                for (
                  var index = 0;
                  index < addresses.length;
                  index++
                ) ...<Widget>[
                  _SavedAddressCard(
                    address: addresses[index],
                    updating: backend.addressesUpdating,
                    onMakeDefault: () => _makeDefault(addresses[index]),
                    onDelete: () => _confirmDelete(addresses[index]),
                  ),
                  if (index != addresses.length - 1) const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
      floatingActionButton: addresses.isEmpty
          ? null
          : FloatingActionButton.extended(
              key: const ValueKey<String>('add-address-button'),
              onPressed: backend.addressesUpdating ? null : _addAddress,
              backgroundColor: BaseColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(t.addAddress),
            ),
    );
  }
}

class _SavedAddressCard extends StatelessWidget {
  const _SavedAddressCard({
    required this.address,
    required this.updating,
    required this.onMakeDefault,
    required this.onDelete,
  });

  final ClientAddress address;
  final bool updating;
  final Future<void> Function() onMakeDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return _ProfileCardShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          address.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.ui(
                            size: 15,
                            height: 20 / 15,
                            weight: FontWeight.w600,
                            color: _ProfilePalette.primary(context),
                          ),
                        ),
                      ),
                      if (address.isDefault) ...<Widget>[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _ProfilePalette.actionSoft(context),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            t.defaultAddress,
                            style: AppTextStyles.ui(
                              size: 11,
                              height: 14 / 11,
                              weight: FontWeight.w600,
                              color: BaseColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatSavedAddress(address),
                    style: AppTextStyles.ui(
                      size: 13.5,
                      height: 19 / 13.5,
                      color: _ProfilePalette.secondary(context),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<_SavedAddressAction>(
              enabled: !updating,
              onSelected: (action) {
                switch (action) {
                  case _SavedAddressAction.makeDefault:
                    unawaited(onMakeDefault());
                  case _SavedAddressAction.delete:
                    onDelete();
                }
              },
              itemBuilder: (context) => <PopupMenuEntry<_SavedAddressAction>>[
                if (!address.isDefault)
                  PopupMenuItem<_SavedAddressAction>(
                    value: _SavedAddressAction.makeDefault,
                    child: Text(t.setAsDefault),
                  ),
                PopupMenuItem<_SavedAddressAction>(
                  value: _SavedAddressAction.delete,
                  child: Text(
                    t.deleteAddress,
                    style: TextStyle(color: _ProfilePalette.danger(context)),
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

class _SavedAddressesEmpty extends StatelessWidget {
  const _SavedAddressesEmpty({required this.onAdd});

  final Future<void> Function() onAdd;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _ProfilePalette.actionSoft(context),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: BaseColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.noSavedAddresses,
            style: AppTextStyles.display(
              size: 21,
              height: 24 / 21,
              color: _ProfilePalette.primary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.noSavedAddressesSubtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.ui(
              size: 13.5,
              height: 19 / 13.5,
              color: _ProfilePalette.secondary(context),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const ValueKey<String>('add-address-button'),
            onPressed: () => unawaited(onAdd()),
            icon: const Icon(Icons.add_rounded),
            label: Text(t.addAddress),
          ),
        ],
      ),
    );
  }
}

enum _SavedAddressAction { makeDefault, delete }

class _AddressDetails {
  const _AddressDetails({required this.label, required this.makeDefault});

  final String label;
  final bool makeDefault;
}

Future<_AddressDetails?> _showAddressDetailsSheet(
  BuildContext context, {
  required bool makeDefault,
}) {
  return showAppModalBottomSheet<_AddressDetails>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddressDetailsSheet(initialDefault: makeDefault),
  );
}

class _AddressDetailsSheet extends StatefulWidget {
  const _AddressDetailsSheet({required this.initialDefault});

  final bool initialDefault;

  @override
  State<_AddressDetailsSheet> createState() => _AddressDetailsSheetState();
}

class _AddressDetailsSheetState extends State<_AddressDetailsSheet> {
  late final TextEditingController _labelController;
  late bool _makeDefault;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();
    _makeDefault = widget.initialDefault;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: _ProfilePalette.surface(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDesignTokens.radiusSheet),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const AppBottomSheetDragHandle(),
          const SizedBox(height: 10),
          Text(
            t.addAddress,
            style: AppTextStyles.display(
              size: 21,
              height: 24 / 21,
              color: _ProfilePalette.primary(context),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            autofocus: true,
            controller: _labelController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: t.addressLabel,
              hintText: t.addressLabelHint,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _makeDefault,
            onChanged: widget.initialDefault
                ? null
                : (value) => setState(() => _makeDefault = value),
            title: Text(t.setAsDefault),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _labelController.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(
                    _AddressDetails(
                      label: _labelController.text.trim(),
                      makeDefault: _makeDefault,
                    ),
                  ),
            child: Text(t.save),
          ),
        ],
      ),
    );
  }
}

ClientAddressInput _addressInput(
  ClientAddress address, {
  required bool isDefault,
}) {
  return ClientAddressInput(
    label: address.label,
    street: address.street,
    houseNumber: address.houseNumber,
    apartmentNumber: address.apartmentNumber,
    entrance: address.entrance,
    floor: address.floor,
    doorCode: address.doorCode,
    latitude: address.latitude,
    longitude: address.longitude,
    comment: address.comment,
    isDefault: isDefault,
  );
}

String _formatSavedAddress(ClientAddress address) {
  final parts = <String>[address.street];
  if (address.houseNumber?.trim().isNotEmpty == true) {
    parts.add(address.houseNumber!.trim());
  }
  return parts.join(', ');
}

String? _nullIfEmpty(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
