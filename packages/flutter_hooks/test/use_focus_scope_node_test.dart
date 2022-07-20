import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('creates a focus scope node and disposes it', (tester) async {
    late FocusScopeNode focusScopeNode;
    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        focusScopeNode = useFocusScopeNode();
        return Container();
      }),
    );

    expect(focusScopeNode, isA<FocusScopeNode>());
    // ignore: invalid_use_of_protected_member
    expect(focusScopeNode.hasListeners, isFalse);

    final previousValue = focusScopeNode;

    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        focusScopeNode = useFocusScopeNode();
        return Container();
      }),
    );

    expect(previousValue, focusScopeNode);
    // ignore: invalid_use_of_protected_member
    expect(focusScopeNode.hasListeners, isFalse);

    await tester.pumpWidget(Container());

    expect(
      // ignore: invalid_use_of_protected_member
      () => focusScopeNode.hasListeners,
      throwsAssertionError,
    );
  });

  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useFocusScopeNode();
        return const SizedBox();
      }),
    );

    final element = tester.element(find.byType(HookBuilder));

    expect(
      element
          .toDiagnosticsNode(style: DiagnosticsTreeStyle.offstage)
          .toStringDeep(),
      equalsIgnoringHashCodes(
        'HookBuilder\n'
        ' │ useFocusScopeNode: FocusScopeNode#00000\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  testWidgets('default values matches with FocusScopeNode', (tester) async {
    final official = FocusScopeNode();

    late FocusScopeNode focusScopeNode;
    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        focusScopeNode = useFocusScopeNode();
        return Container();
      }),
    );

    expect(focusScopeNode.debugLabel, official.debugLabel);
    expect(focusScopeNode.onKey, official.onKey);
    expect(focusScopeNode.skipTraversal, official.skipTraversal);
    expect(focusScopeNode.canRequestFocus, official.canRequestFocus);
    expect(focusScopeNode.descendantsAreFocusable, official.descendantsAreFocusable);
  });

  testWidgets('has all the FocusScopeNode parameters', (tester) async {
    KeyEventResult onKey(FocusScopeNode node, RawKeyEvent event) =>
        KeyEventResult.ignored;

    KeyEventResult onKeyEvent(FocusScopeNode node, KeyEvent event) =>
        KeyEventResult.ignored;

    late FocusScopeNode focusScopeNode;
    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        focusScopeNode = useFocusScopeNode(
          debugLabel: 'Foo',
          onKey: onKey,
          onKeyEvent: onKeyEvent,
          skipTraversal: true,
          canRequestFocus: false,
          descendantsAreFocusable: false,
        );
        return Container();
      }),
    );

    expect(focusScopeNode.debugLabel, 'Foo');
    expect(focusScopeNode.onKey, onKey);
    expect(focusScopeNode.onKeyEvent, onKeyEvent);
    expect(focusScopeNode.skipTraversal, true);
    expect(focusScopeNode.canRequestFocus, false);
    expect(focusScopeNode.descendantsAreFocusable, false);
  });

  testWidgets('handles parameter change', (tester) async {
    KeyEventResult onKey(FocusScopeNode node, RawKeyEvent event) =>
        KeyEventResult.ignored;
    KeyEventResult onKey2(FocusScopeNode node, RawKeyEvent event) =>
        KeyEventResult.ignored;

    KeyEventResult onKeyEvent(FocusScopeNode node, KeyEvent event) =>
        KeyEventResult.ignored;
    KeyEventResult onKeyEvent2(FocusScopeNode node, KeyEvent event) =>
        KeyEventResult.ignored;

    late FocusScopeNode focusScopeNode;
    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        focusScopeNode = useFocusScopeNode(
          debugLabel: 'Foo',
          onKey: onKey,
          onKeyEvent: onKeyEvent,
          skipTraversal: true,
          canRequestFocus: false,
          descendantsAreFocusable: false,
        );

        return Container();
      }),
    );

    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        focusScopeNode = useFocusScopeNode(
          debugLabel: 'Bar',
          onKey: onKey2,
          onKeyEvent: onKeyEvent2,
        );

        return Container();
      }),
    );

    expect(focusScopeNode.onKey, onKey2);
    expect(focusScopeNode.onKeyEvent, onKeyEvent2);
    expect(focusScopeNode.debugLabel, 'Bar');
    expect(focusScopeNode.skipTraversal, false);
    expect(focusScopeNode.canRequestFocus, true);
    expect(focusScopeNode.descendantsAreFocusable, true);
  });
}
