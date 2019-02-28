import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('usePageController basic', (tester) async {
    PageController controller;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        controller = usePageController();
        return Container();
      }),
    );

    expect(controller.initialPage, 0);
    expect(controller.viewportFraction, 1.0);
    expect(controller.keepPage, true);

    // dispose
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('usePageController complex', (tester) async {
    PageController controller;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        controller = usePageController(
          initialPage: 1,
          viewportFraction: 2.0,
          keepPage: false,
        );
        return Container();
      }),
    );

    expect(controller.initialPage, 1);
    expect(controller.viewportFraction, 2.0);
    expect(controller.keepPage, false);

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        controller = usePageController(
          initialPage: 2,
          viewportFraction: 4.0,
          keepPage: true,
        );
        return Container();
      }),
    );

    expect(controller.initialPage, 1);
    expect(controller.viewportFraction, 2.0);
    expect(controller.keepPage, false);

    // dispose
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('usePageController pass down keys', (tester) async {
    List keys;
    PageController controller;
    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        controller = usePageController(keys: keys);
        return Container();
      },
    ));

    final previous = controller;
    keys = <dynamic>[];

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        controller = usePageController(keys: keys);
        return Container();
      },
    ));

    expect(previous, isNot(controller));
  });
}
