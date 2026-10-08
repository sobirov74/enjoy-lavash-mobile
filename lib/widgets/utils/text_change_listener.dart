import 'package:flutter/widgets.dart';

/// A [TextEditingController] listener that calls [onChanged] only when the
/// text itself changes.
///
/// Controllers also notify for cursor moves, selection, focus and IME
/// composing updates. Treating those as edits re-runs whatever depends on the
/// text (for checkout: clearing the computed total and requesting a new
/// cart preview).
VoidCallback textChangeListener(
  TextEditingController controller,
  VoidCallback onChanged,
) {
  var lastText = controller.text;
  return () {
    final text = controller.text;
    if (text == lastText) return;
    lastText = text;
    onChanged();
  };
}
