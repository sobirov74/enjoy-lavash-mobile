import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/utils/date_formatter.dart';
import 'package:enjoy_lavash_mobile/theme/theme_extensions.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';

String _statusMessage(BuildContext context, String status) {
  final t = L.of(context);
  switch (status) {
    case 'COMPLETED':
      return t.statusCompleted;
    case 'ACCEPTED':
      return t.statusAccepted;
    case 'CANCELLED':
      return t.statusCancelled;
    case 'FAILED':
      return t.statusFailed;
    case 'IN_PROGRESS':
      return t.statusInProgress;
    case 'NEW':
      return t.statusNew;
    default:
      return "";
  }
}

Color getStatusColor(String status) {
  switch (status) {
    case 'NEW':
      return Color(0xFF3B82F6);
    case "ACCEPTED":
      return Color(0xFF22C55E);
    case "CANCELLED":
      return Color(0xFFFF5757);
    case "FAILED":
      return Color(0xFFEC4899);
    case "COMPLETED":
      return Color(0xFF10B981);
    case "IN_PROGRESS":
      return Color(0xFFF59E0B);
    default:
      return Color(0xFFF59E0B);
  }
}

class StatusData {
  final String text;
  final Color color;

  const StatusData({required this.text, required this.color});
}

StatusData getStatusData(BuildContext context, String status) {
  final t = L.of(context);
  switch (status) {
    case "COMPLETED":
      return StatusData(text: t.statusArchive, color: context.colors.primary);
    case "IN_PROGRESS":
      return StatusData(
        text: t.statusNeedAccept,
        color: context.colors.danger,
      );
    default:
      return StatusData(text: '', color: context.colors.primary);
  }
}

class OrderCard extends StatelessWidget {
  final int number;
  final DateTime? date;
  final String branch;
  final List<String>? products;
  final String status;
  final bool isDark;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.number,
    required this.date,
    required this.branch,
    required this.status,
    required this.isDark,
    this.products,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusData = getStatusData(context, status);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
        decoration: BoxDecoration(
          color: isDark ? BaseColors.black600 : BaseColors.baseBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// LEFT SIDE
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TypographyText(
                    '#$number',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (date != null) const SizedBox(height: 6),
                  if (date != null)
                    TypographyText(
                      date!.formatLocal(),
                      style: const TextStyle(fontSize: 13),
                    ),
                  const SizedBox(height: 4),
                  TypographyText(branch, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TypographyText(
                        L.of(context).status,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        width: 70,
                        decoration: BoxDecoration(
                          color: getStatusColor(status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TypographyText(
                          _statusMessage(context, status),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// Divider
            Container(
              width: 1,
              height: 110,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: context.colors.border,
            ),

            /// RIGHT SIDE
            if (products != null)
              Expanded(
                flex: 1,
                child: Container(
                  height: 110,
                  alignment: Alignment.center,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...products!.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: 4,
                                left: 0,
                              ),
                              child: TypographyText(
                                item,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TypographyText(
                              statusData.text,
                              style: TextStyle(
                                color: statusData.color,
                                fontSize: 12,
                              ),

                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // SizedBox(width: 4),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            Container(
              height: 110,
              alignment: Alignment.center,
              child: SvgPicture.asset('assets/icons/arrow.svg', height: 15),
            ),
          ],
        ),
      ),
    );
  }
}
