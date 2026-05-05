import 'package:flutter/material.dart';
import 'package:enjoy_lavash_mobile/core/data/models/order_product.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/theme/theme_extensions.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:enjoy_lavash_mobile/widgets/ui/quantity_field.dart';

class OrderProductsTable extends StatelessWidget {
  final List<OrderProducts> items;
  final String id;
  const OrderProductsTable({super.key, required this.items, required this.id});

  // OrderProductRepository

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader(context);
        }

        final item = items[index - 1];
        return _buildRow(context, index, item);
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: BaseColors.primary,
      child: Row(
        children: [
          _HeaderCell(flex: 1, text: L.of(context).tableNumber),
          _HeaderCell(flex: 5, text: L.of(context).tableName),
          _HeaderCell(flex: 2, text: L.of(context).tableSent),
          _HeaderCell(flex: 2, text: L.of(context).tableReceived),
          _HeaderCell(flex: 2, text: L.of(context).tableDifference),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, int index, OrderProducts item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.background,
        border: Border(bottom: BorderSide(color: context.colors.border)),
      ),
      child: Row(
        children: [
          _BodyCell(flex: 1, child: TypographyText(index.toString())),
          _BodyCell(flex: 5, child: TypographyText(item.product.name)),
          _BodyCell(
            flex: 2,
            child: TypographyText(item.shippedUnits.toString()),
          ),
          _BodyCell(
            flex: 2,
            child: SizedBox(
              height: 36,
              child: QuantityField(
                productId: item.id,
                initialValue: item.deliveredUnits?.toString() ?? "",
                id: id,
              ),
            ),
          ),
          _BodyCell(
            flex: 2,
            child: TypographyText(
              item.shippedUnits != null && item.deliveredUnits != null
                  ? '${(item.deliveredUnits ?? 0) - item.shippedUnits!}'
                  : "0",
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final int flex;
  final String text;

  const _HeaderCell({required this.flex, required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TypographyText(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: BaseColors.black,
          ),
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final int flex;
  final Widget child;

  const _BodyCell({required this.flex, required this.child});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: child,
      ),
    );
  }
}
