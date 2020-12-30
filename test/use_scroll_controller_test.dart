import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hooks/src/framework.dart';
import 'package:flutter_hooks/src/hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        h.useScrollController();
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
        ' │ useScrollController: ScrollController#00000(no clients)\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  group('useScrollController', () {
    testWidgets('initial values matches with real constructor', (tester) async {
      ScrollController controller;
      ScrollController controller2;

      await tester.pumpWidget(
        HookBuilder(builder: (context, h) {
          controller2 = ScrollController();
          controller = h.useScrollController();
          return Container();
        }),
      );

      expect(controller.debugLabel, controller2.debugLabel);
      expect(controller.initialScrollOffset, controller2.initialScrollOffset);
      expect(controller.keepScrollOffset, controller2.keepScrollOffset);
    });
    testWidgets("returns a ScrollController that doesn't change",
        (tester) async {
      ScrollController controller;
      ScrollController controller2;

      await tester.pumpWidget(
        HookBuilder(builder: (context, h) {
          controller = h.useScrollController();
          return Container();
        }),
      );

      expect(controller, isA<ScrollController>());

      await tester.pumpWidget(
        HookBuilder(builder: (context, h) {
          controller2 = h.useScrollController();
          return Container();
        }),
      );

      expect(identical(controller, controller2), isTrue);
    });

    testWidgets('passes hook parameters to the ScrollController',
        (tester) async {
      ScrollController controller;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context, h) {
            controller = h.useScrollController(
              initialScrollOffset: 42,
              debugLabel: 'Hello',
              keepScrollOffset: false,
            );

            return Container();
          },
        ),
      );

      expect(controller.initialScrollOffset, 42);
      expect(controller.debugLabel, 'Hello');
      expect(controller.keepScrollOffset, false);
    });
  });
}

class TickerProviderMock extends Mock implements TickerProvider {}
