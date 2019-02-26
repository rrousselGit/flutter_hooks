import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('useTextEditingController basic', (tester) async {
    TextEditingController controller;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        controller = useTextEditingController();
        return Container();
      }),
    );

    expect(controller.text, '');

    // dispose
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('useTextEditingController complex', (tester) async {
    TextEditingController controller;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        controller = useTextEditingController(
          text: 'Foo',
        );
        return Container();
      }),
    );

    expect(controller.text, 'Foo');

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        controller = useTextEditingController(
          text: 'Bar',
        );
        return Container();
      }),
    );

    expect(controller.text, 'Bar');

    // dispose
    await tester.pumpWidget(const SizedBox());
  });
}
