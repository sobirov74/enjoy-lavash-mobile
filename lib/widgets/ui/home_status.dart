import 'package:flutter/material.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:enjoy_lavash_mobile/widgets/white_container.dart';

class HomeStatus extends StatelessWidget {
  final String time;
  final int? docsCount;
  const HomeStatus({super.key, required this.time, this.docsCount});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WhiteContainer(
      margin: EdgeInsetsGeometry.directional(bottom: 12, top: 12),
      child: Material(
        color: isDark ? BaseColors.black600 : BaseColors.baseBg,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TypographyText(
                      // 'Товар в пути',
                      "Скоро...",
                      weight: FontWeightType.bold,
                      style: TextStyle(fontSize: 18),
                    ),
                    // Row(
                    //   children: [
                    //     TypographyText(
                    //       'Время поставки: ',
                    //       // weight: FontWeightType.thin,
                    //       style: TextStyle(fontSize: 12),
                    //     ),
                    //     TypographyText(
                    //       time,
                    //       // weight: FontWeightType.thin,
                    //       style: TextStyle(
                    //         fontSize: 12,
                    //         color: BaseColors.primary,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // if (docsCount != null && docsCount! > 0)
                    //   TypographyText(
                    //     'Документов: $docsCount шт',
                    //     weight: FontWeightType.bold,
                    //     style: TextStyle(fontSize: 12),
                    //   ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Image(
                  image: AssetImage('assets/images/truck.png'),
                  // height: 60,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
