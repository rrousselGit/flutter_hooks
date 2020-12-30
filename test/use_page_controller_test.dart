import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/src/framework.dart';
import 'package:flutter_hooks/src/hooks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        h.usePageController();
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
        ' │ usePageController: PageController#00000(no clients)\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  group('usePageController', () {
    testWidgets('initial values matches with real constructor', (tester) async {
      PageController controller;
      PageController controller2;

      await tester.pumpWidget(
        HookBuilder(builder: (context, h) {
          controller2 = PageController();
          controller = h.usePageController();
          return Container();
        }),
      );

      expect(controller.initialPage, controller2.initialPage);
      expect(controller.keepPage, controller2.keepPage);
      expect(controller.viewportFraction, controller2.viewportFraction);
    });
    testWidgets("returns a PageController that doesn't change", (tester) async {
      PageController controller;
      PageController controller2;

      await tester.pumpWidget(
        HookBuilder(builder: (context, h) {
          controller = h.usePageController();
          return Container();
        }),
      );

      expect(controller, isA<PageController>());

      await tester.pumpWidget(
        HookBuilder(builder: (context, h) {
          controller2 = h.usePageController();
          return Container();
        }),
      );

      expect(identical(controller, controller2), isTrue);
    });

    testWidgets('passes hook parameters to the PageController', (tester) async {
      PageController controller;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context, h) {
            controller = h.usePageController(
              initialPage: 42,
              keepPage: false,
              viewportFraction: 3.4,
            );

            return Container();
          },
        ),
      );

      expect(controller.initialPage, 42);
      expect(controller.keepPage, false);
      expect(controller.viewportFraction, 3.4);
    });

    testWidgets('disposes the PageController on unmount', (tester) async {
      PageController controller;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context, h) {
            controller = h.usePageController();
            return Container();
          },
        ),
      );

      // pump another widget so that the old one gets disposed
      await tester.pumpWidget(Container());

      expect(
        () => controller.addListener(null),
        throwsA(isFlutterError.having(
            (e) => e.message, 'message', contains('disposed'))),
      );
    });
  });
}
