import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('useScrollController basic', (tester) async {
    ScrollController controller;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        controller = useScrollController();
        return Container();
      }),
    );

    expect(controller.initialScrollOffset, 0.0);
    expect(controller.keepScrollOffset, true);

    // dispose
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('useScrollController complex', (tester) async {
    ScrollController controller;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        controller = useScrollController(
          initialScrollOffset: 50.0,
          keepScrollOffset: false,
          debugLabel: 'Foo',
        );
        return Container();
      }),
    );

    expect(controller.initialScrollOffset, 50.0);
    expect(controller.keepScrollOffset, false);
    expect(controller.debugLabel, 'Foo');

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        controller = useScrollController(
          initialScrollOffset: 20.0,
          keepScrollOffset: true,
          debugLabel: 'Bar',
        );
        return Container();
      }),
    );

    expect(controller.initialScrollOffset, 50.0);
    expect(controller.keepScrollOffset, false);
    expect(controller.debugLabel, 'Foo');

    // dispose
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('useScrollController pass down keys', (tester) async {
    List keys;
    ScrollController controller;
    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        controller = useScrollController(keys: keys);
        return Container();
      },
    ));

    final previous = controller;
    keys = <dynamic>[];

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        controller = useScrollController(keys: keys);
        return Container();
      },
    ));

    expect(previous, isNot(controller));
  });
}
