import 'package:enjoy_lavash_mobile/widgets/utils/text_change_listener.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only text edits count, not cursor or composing updates', () {
    final controller = TextEditingController(text: 'LAVASH');
    addTearDown(controller.dispose);
    var edits = 0;
    controller.addListener(textChangeListener(controller, () => edits++));

    controller.selection = const TextSelection.collapsed(offset: 2);
    controller.value = controller.value.copyWith(
      composing: const TextRange(start: 0, end: 2),
    );
    expect(edits, 0);

    controller.text = 'LAVASH10';
    expect(edits, 1);

    // Setting text then moving the cursor (as "use all points" does) is one
    // edit, not two.
    controller.text = '5000';
    controller.selection = const TextSelection.collapsed(offset: 4);
    expect(edits, 2);
  });
}
