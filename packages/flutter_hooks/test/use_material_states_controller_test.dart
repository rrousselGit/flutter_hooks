import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/src/framework.dart';
import 'package:flutter_hooks/src/hooks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useWidgetStatesController();
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
        ' │ useWidgetStatesController: WidgetStatesController#00000({})\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  group('useWidgetStatesController', () {
    testWidgets('initial values matches with real constructor', (tester) async {
      late WidgetStatesController controller;
      late WidgetStatesController controller2;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller2 = WidgetStatesController();
          controller = useWidgetStatesController();
          return Container();
        }),
      );

      expect(controller.value, controller2.value);
    });
    testWidgets("returns a WidgetStatesController that doesn't change",
        (tester) async {
      late WidgetStatesController controller;
      late WidgetStatesController controller2;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller = useWidgetStatesController();
          return Container();
        }),
      );

      expect(controller, isA<WidgetStatesController>());

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller2 = useWidgetStatesController();
          return Container();
        }),
      );

      expect(identical(controller, controller2), isTrue);
    });

    testWidgets('passes hook parameters to the WidgetStatesController',
        (tester) async {
      late WidgetStatesController controller;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            controller = useWidgetStatesController(
              values: {WidgetState.selected},
            );

            return Container();
          },
        ),
      );

      expect(controller.value, {WidgetState.selected});
    });

    testWidgets('disposes the WidgetStatesController on unmount',
        (tester) async {
      late WidgetStatesController controller;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            controller = useWidgetStatesController();
            return Container();
          },
        ),
      );

      // pump another widget so that the old one gets disposed
      await tester.pumpWidget(Container());

      expect(
        () => controller.addListener(() {}),
        throwsA(isFlutterError.having(
            (e) => e.message, 'message', contains('disposed'))),
      );
    });
  });
}
