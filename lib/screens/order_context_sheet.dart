import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/address_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/widgets/app_bottom_sheet_drag_handle.dart';
import 'package:enjoy_lavash_mobile/widgets/app_modal_bottom_sheet.dart';
import 'package:flutter/material.dart';

Future<void> showOrderContextSheet({
  required BuildContext context,
  required MobileOrderType currentType,
  required BranchModel? selectedBranch,
  required List<BranchModel> branches,
  required String? deliveryAddress,
  required ValueChanged<MobileOrderType> onTypeChanged,
  required Future<void> Function(BranchModel?) onBranchSelected,
}) async {
  final result = await showAppModalBottomSheet<_OrderContextResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    builder: (_) => _OrderContextSheet(
      currentType: currentType,
      selectedBranch: selectedBranch,
      branches: branches,
      deliveryAddress: deliveryAddress,
    ),
  );
  if (result == null || !context.mounted) return;

  onTypeChanged(result.type);
  if (result.type == MobileOrderType.pickup) {
    await onBranchSelected(result.branch);
    return;
  }
  if (result.editDeliveryAddress && context.mounted) {
    await showAddressBottomSheet(context);
  }
}

class _OrderContextResult {
  const _OrderContextResult({
    required this.type,
    required this.branch,
    this.editDeliveryAddress = false,
  });

  final MobileOrderType type;
  final BranchModel? branch;
  final bool editDeliveryAddress;
}

class _OrderContextSheet extends StatefulWidget {
  const _OrderContextSheet({
    required this.currentType,
    required this.selectedBranch,
    required this.branches,
    required this.deliveryAddress,
  });

  final MobileOrderType currentType;
  final BranchModel? selectedBranch;
  final List<BranchModel> branches;
  final String? deliveryAddress;

  @override
  State<_OrderContextSheet> createState() => _OrderContextSheetState();
}

class _OrderContextSheetState extends State<_OrderContextSheet> {
  late MobileOrderType _type = widget.currentType;
  late BranchModel? _branch = widget.selectedBranch;
  bool _editDeliveryAddress = false;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.84,
      ),
      padding: EdgeInsets.fromLTRB(
        AppDesignTokens.gutter,
        10,
        AppDesignTokens.gutter,
        18 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppDesignTokens.ground(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDesignTokens.radiusSheet),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppBottomSheetDragHandle(color: AppDesignTokens.hairline(context)),
          const SizedBox(height: 12),
          Text(
            t.orderType,
            style: AppTextStyles.display(
              size: 21,
              height: 1.2,
              color: AppDesignTokens.primaryText(context),
            ),
          ),
          const SizedBox(height: 14),
          _TypeSegment(
            value: _type,
            onChanged: (value) => setState(() => _type = value),
          ),
          const SizedBox(height: 20),
          Text(
            _type == MobileOrderType.delivery ? t.address : t.pickupBranch,
            style: AppTextStyles.ui(
              size: 17,
              weight: FontWeight.w600,
              color: AppDesignTokens.primaryText(context),
            ),
          ),
          const SizedBox(height: 10),
          if (_type == MobileOrderType.delivery)
            _DeliveryAddressCard(
              label: widget.deliveryAddress?.trim().isNotEmpty == true
                  ? widget.deliveryAddress!.trim()
                  : t.tapToSelectAddress,
              selected: _editDeliveryAddress,
              onTap: () => setState(() => _editDeliveryAddress = true),
            )
          else
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: AppDesignTokens.surface(context),
                  borderRadius: BorderRadius.circular(
                    AppDesignTokens.radiusCard,
                  ),
                  boxShadow: AppDesignTokens.cardShadow(context),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.branches.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    indent: 16,
                    color: AppDesignTokens.hairline(context),
                  ),
                  itemBuilder: (context, index) {
                    final branch = widget.branches[index];
                    return _BranchRow(
                      branch: branch,
                      selected: branch.id == _branch?.id,
                      onTap: () => setState(() => _branch = branch),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: AppDesignTokens.primaryButtonHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
                boxShadow: AppDesignTokens.actionGlow,
              ),
              child: FilledButton(
                onPressed: _type == MobileOrderType.pickup && _branch == null
                    ? null
                    : () => Navigator.of(context).pop(
                        _OrderContextResult(
                          type: _type,
                          branch: _branch,
                          editDeliveryAddress: _editDeliveryAddress,
                        ),
                      ),
                child: Text(t.save),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeSegment extends StatelessWidget {
  const _TypeSegment({required this.value, required this.onChanged});

  final MobileOrderType value;
  final ValueChanged<MobileOrderType> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppDesignTokens.primaryText(context).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusTile),
      ),
      child: Row(
        children: <Widget>[
          _SegmentOption(
            label: t.delivery,
            selected: value == MobileOrderType.delivery,
            onTap: () => onChanged(MobileOrderType.delivery),
          ),
          _SegmentOption(
            label: t.pickup,
            selected: value == MobileOrderType.pickup,
            onTap: () => onChanged(MobileOrderType.pickup),
          ),
        ],
      ),
    );
  }
}

class _SegmentOption extends StatelessWidget {
  const _SegmentOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppDesignTokens.surface(context) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusInput),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusInput),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.ui(
                size: 13.5,
                weight: FontWeight.w600,
                color: selected
                    ? AppDesignTokens.primaryText(context)
                    : AppDesignTokens.secondaryText(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeliveryAddressCard extends StatelessWidget {
  const _DeliveryAddressCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppDesignTokens.surface(context),
      borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppDesignTokens.actionSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: AppDesignTokens.action,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.ui(
                    size: 14.5,
                    weight: FontWeight.w600,
                    color: AppDesignTokens.primaryText(context),
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.chevron_right,
                color: selected
                    ? AppDesignTokens.action
                    : AppDesignTokens.tertiaryText(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BranchRow extends StatelessWidget {
  const _BranchRow({
    required this.branch,
    required this.selected,
    required this.onTap,
  });

  final BranchModel branch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    branch.name,
                    style: AppTextStyles.ui(
                      size: 15,
                      weight: FontWeight.w600,
                      color: AppDesignTokens.primaryText(context),
                    ),
                  ),
                  if (branch.address?.trim().isNotEmpty == true)
                    Text(
                      branch.address!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.ui(
                        size: 11.5,
                        color: AppDesignTokens.tertiaryText(context),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppDesignTokens.action : Colors.transparent,
                shape: BoxShape.circle,
                border: selected
                    ? null
                    : Border.all(color: AppDesignTokens.hairline(context)),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
