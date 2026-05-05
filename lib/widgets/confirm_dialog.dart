import 'package:flutter/material.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';

Future<void> showConfirmDialog({
  required BuildContext context,
  required String title,
  required VoidCallback onConfirm,
  VoidCallback? onCancel,
  String confirmText = 'Yes',
  String cancelText = 'No',
  Widget? child,
  bool footerReversed = false,
  bool loading = false,
}) {
  return showDialog(
    context: context,
    barrierDismissible: onCancel != null,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? Colors.black : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TypographyText(
                  title,

                  // textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                if (child != null) ...[const SizedBox(height: 16), child],

                const SizedBox(height: 20),

                Row(
                  children: footerReversed
                      ? _reversedButtons(
                          context,
                          onConfirm,
                          onCancel,
                          confirmText,
                          cancelText,
                          loading,
                        )
                      : _normalButtons(
                          context,
                          onConfirm,
                          onCancel,
                          confirmText,
                          cancelText,
                          loading,
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

List<Widget> _normalButtons(
  BuildContext context,
  VoidCallback onConfirm,
  VoidCallback? onCancel,
  String confirmText,
  String cancelText,
  bool loading,
) {
  return [
    Expanded(
      child: ElevatedButton(
        onPressed: loading
            ? null
            : () {
                Navigator.of(context).pop();
                onConfirm();
              },
        child: loading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TypographyText(confirmText),
      ),
    ),
    if (onCancel != null) ...[
      const SizedBox(width: 20),
      Expanded(
        child: OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onCancel();
          },
          child: TypographyText(cancelText),
        ),
      ),
    ],
  ];
}

List<Widget> _reversedButtons(
  BuildContext context,
  VoidCallback onConfirm,
  VoidCallback? onCancel,
  String confirmText,
  String cancelText,
  bool loading,
) {
  return _normalButtons(
    context,
    onConfirm,
    onCancel,
    confirmText,
    cancelText,
    loading,
  ).reversed.toList();
}
