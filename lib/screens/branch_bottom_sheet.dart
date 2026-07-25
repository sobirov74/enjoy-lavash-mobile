import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/app_bottom_sheet_drag_handle.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<BranchModel?> showBranchBottomSheet(
  BuildContext context, {
  String? selectedBranchId,
}) {
  return showModalBottomSheet<BranchModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    isDismissible: true,
    showDragHandle: false,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<MobileBackendController>(),
      child: _BranchSheet(selectedBranchId: selectedBranchId),
    ),
  );
}

class _BranchSheet extends StatelessWidget {
  const _BranchSheet({this.selectedBranchId});

  final String? selectedBranchId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = L.of(context);
    final branches = context
        .watch<MobileBackendController>()
        .branches
        .where((branch) => branch.isActive)
        .toList(growable: false);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1A18) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBottomSheetDragHandle(
            margin: const EdgeInsets.only(top: 4),
            color: isDark ? const Color(0xFF3A3530) : const Color(0xFFE0DBD5),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TypographyText(
                    t.selectBranch,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2522)
                          : const Color(0xFFF3F0EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.close_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: branches.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: TypographyText(
                      t.emptyList,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF9E9790)
                            : BaseColors.textGray,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    shrinkWrap: true,
                    itemCount: branches.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final branch = branches[index];
                      return _BranchCard(
                        branch: branch,
                        isDark: isDark,
                        isSelected: branch.id == selectedBranchId,
                        onTap: () => Navigator.pop(context, branch),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({
    required this.branch,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
  });

  final BranchModel branch;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;

  String get _workingHours {
    final openingTime = branch.openingTime;
    final closingTime = branch.closingTime;
    if (openingTime?.isNotEmpty == true && closingTime?.isNotEmpty == true) {
      return '$openingTime - $closingTime';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final workingHours = _workingHours;

    return Semantics(
      key: ValueKey<String>('branch-card-${branch.id}'),
      button: true,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? BaseColors.primary.withValues(alpha: isDark ? 0.16 : 0.10)
                : (isDark ? const Color(0xFF2A2522) : const Color(0xFFF8F4EF)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? BaseColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: BaseColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: BaseColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TypographyText(
                      branch.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (branch.address?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      TypographyText(
                        branch.address!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF9E9790)
                              : BaseColors.textGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (workingHours.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: BaseColors.primary,
                          ),
                          const SizedBox(width: 4),
                          TypographyText(
                            workingHours,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: BaseColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: isSelected
                    ? BaseColors.primary
                    : (isDark ? const Color(0xFF9E9790) : BaseColors.textGray),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
