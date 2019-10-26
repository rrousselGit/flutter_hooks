import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/src/framework.dart';
import 'package:flutter_hooks/src/hooks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock.dart';

void main() {
  testWidgets('throws when both initial text and value is set', (tester) {
    return expectPump(
      () => tester.pumpWidget(HookBuilder(
        builder: (context) {
          useTextEditingController(
            initialText: 'foo',
            initialValue: TextEditingValue.empty,
          );
          return Container();
        },
      )),
      throwsAssertionError,
    );
  });

  testWidgets('useTextEditingController returns a controller', (tester) async {
    TextEditingController controller;

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        controller = useTextEditingController();
        return Container();
      },
    ));

    expect(controller, isNotNull);
    controller.addListener(() {});

    // pump another widget so that the old one gets disposed
    await tester.pumpWidget(Container());

    expect(() => controller.addListener(null), throwsA((FlutterError error) {
      return error.message.contains('disposed');
    }));
  });

  testWidgets('respects initialText property', (tester) async {
    TextEditingController controller;

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        controller = useTextEditingController(initialText: 'hello hooks');
        return Container();
      },
    ));

    expect(controller.text, 'hello hooks');
  });

  testWidgets('respects initialValue property', (tester) async {
    const value = TextEditingValue(
        text: 'foo', selection: TextSelection.collapsed(offset: 2));
    TextEditingController controller;

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        controller = useTextEditingController(initialValue: value);
        return Container();
      },
    ));

    expect(controller.value, value);
  });
}
