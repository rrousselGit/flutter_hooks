import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/src/framework.dart';
import 'package:flutter_hooks/src/hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useFixedExtentScrollController();
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
        ' │ useFixedExtentScrollController:\n'
        ' │   FixedExtentScrollController#00000(no clients)\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  group('useFixedExtentScrollController', () {
    testWidgets('initial values matches with real constructor', (tester) async {
      late FixedExtentScrollController controller;
      late FixedExtentScrollController controller2;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller2 = FixedExtentScrollController();
          controller = useFixedExtentScrollController();
          return Container();
        }),
      );

      expect(controller.debugLabel, controller2.debugLabel);
      expect(controller.initialItem, controller2.initialItem);
      expect(controller.onAttach, controller2.onAttach);
      expect(controller.onDetach, controller2.onDetach);
    });
    testWidgets("returns a FixedExtentScrollController that doesn't change",
        (tester) async {
      late FixedExtentScrollController controller;
      late FixedExtentScrollController controller2;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller2 = FixedExtentScrollController();
          controller = useFixedExtentScrollController();
          return Container();
        }),
      );
      expect(controller, isA<FixedExtentScrollController>());

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller2 = useFixedExtentScrollController();
          return Container();
        }),
      );

      expect(identical(controller, controller2), isTrue);
    });

    testWidgets('passes hook parameters to the FixedExtentScrollController',
        (tester) async {
      late FixedExtentScrollController controller;

      void onAttach(ScrollPosition position) {}
      void onDetach(ScrollPosition position) {}

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            controller = useFixedExtentScrollController(
              initialItem: 42,
              onAttach: onAttach,
              onDetach: onDetach,
            );

            return Container();
          },
        ),
      );

      expect(controller.initialItem, 42);
      expect(controller.onAttach, onAttach);
      expect(controller.onDetach, onDetach);
    });
  });
}

class TickerProviderMock extends Mock implements TickerProvider {}
