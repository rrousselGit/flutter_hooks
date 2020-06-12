import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('creates a focus node', (tester) async {
    FocusNode focusNode;
    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        focusNode = useFocusNode();
        return Container();
      }),
    );

    expect(focusNode, isA<FocusNode>());
    // ignore: invalid_use_of_protected_member
    expect(focusNode.hasListeners, isFalse);

    var previous = focusNode;

    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        focusNode = useFocusNode();
        return Container();
      }),
    );

    expect(previous, focusNode);
    // ignore: invalid_use_of_protected_member
    expect(focusNode.hasListeners, isFalse);

    await tester.pumpWidget(Container());

    expect(
      // ignore: invalid_use_of_protected_member
      () => focusNode.hasListeners,
      throwsAssertionError,
    );
  });
}
