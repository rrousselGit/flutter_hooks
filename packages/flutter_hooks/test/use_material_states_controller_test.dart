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
        useMaterialStatesController();
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
        ' │ useMaterialStatesController: MaterialStatesController#00000({})\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  group('useMaterialStatesController', () {
    testWidgets('initial values matches with real constructor', (tester) async {
      late MaterialStatesController controller;
      late MaterialStatesController controller2;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller2 = MaterialStatesController();
          controller = useMaterialStatesController();
          return Container();
        }),
      );

      expect(controller.value, controller2.value);
    });
    testWidgets("returns a MaterialStatesController that doesn't change", (tester) async {
      late MaterialStatesController controller;
      late MaterialStatesController controller2;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller = useMaterialStatesController();
          return Container();
        }),
      );

      expect(controller, isA<MaterialStatesController>());

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller2 = useMaterialStatesController();
          return Container();
        }),
      );

      expect(identical(controller, controller2), isTrue);
    });

    testWidgets('passes hook parameters to the MaterialStatesController', (tester) async {
      late MaterialStatesController controller;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            controller = useMaterialStatesController(
              values: {MaterialState.selected},
            );

            return Container();
          },
        ),
      );

      expect(controller.value, {MaterialState.selected});
    });

    testWidgets('disposes the MaterialStatesController on unmount', (tester) async {
      late MaterialStatesController controller;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            controller = useMaterialStatesController();
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
