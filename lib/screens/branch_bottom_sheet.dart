import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';

class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.workingHours,
  });

  final String id;
  final String name;
  final String address;
  final String workingHours;
}

const List<Branch> mockBranches = [
  Branch(
    id: '1',
    name: 'Enjoy Lavash — Chilanzar',
    address: 'Bunyodkor ko\'chasi, 42',
    workingHours: '09:00 – 23:00',
  ),
  Branch(
    id: '2',
    name: 'Enjoy Lavash — Sergeli',
    address: 'Sergeli ko\'chasi, 7A',
    workingHours: '10:00 – 22:00',
  ),
  Branch(
    id: '3',
    name: 'Enjoy Lavash — Yunusabad',
    address: 'Amir Temur shoh ko\'chasi, 108',
    workingHours: '09:00 – 23:00',
  ),
  Branch(
    id: '4',
    name: 'Enjoy Lavash — Mirzo Ulugbek',
    address: 'Buyuk Ipak Yuli, 56',
    workingHours: '10:00 – 22:30',
  ),
];

Future<Branch?> showBranchBottomSheet(BuildContext context) {
  return showModalBottomSheet<Branch>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _BranchSheet(),
  );
}

class _BranchSheet extends StatelessWidget {
  const _BranchSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = L.of(context);

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
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF3A3530)
                  : const Color(0xFFE0DBD5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
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
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              shrinkWrap: true,
              itemCount: mockBranches.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final branch = mockBranches[index];
                return _BranchCard(
                  branch: branch,
                  isDark: isDark,
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
    required this.onTap,
  });

  final Branch branch;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2522) : const Color(0xFFF8F4EF),
          borderRadius: BorderRadius.circular(20),
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
                  const SizedBox(height: 4),
                  TypographyText(
                    branch.address,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFF9E9790)
                          : BaseColors.textGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                        branch.workingHours,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: BaseColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark
                  ? const Color(0xFF9E9790)
                  : BaseColors.textGray,
            ),
          ],
        ),
      ),
    );
  }
}
