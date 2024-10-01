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
        useCarouselController();
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
        ' │ useCarouselController: CarouselController#00000(no clients)\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  group('useCarouselController', () {
    testWidgets('initial values matches with real constructor', (tester) async {
      late CarouselController controller;
      late CarouselController controller2;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller2 = CarouselController();
          controller = useCarouselController();
          return Container();
        }),
      );

      expect(controller.initialItem, controller2.initialItem);
      expect(controller.initialScrollOffset, controller2.initialScrollOffset);
      expect(controller.keepScrollOffset, controller2.keepScrollOffset);
      expect(controller.onAttach, controller2.onAttach);
      expect(controller.onDetach, controller2.onDetach);
    });

    testWidgets("returns a CarouselController that doesn't change", (tester) async {
      late CarouselController controller;
      late CarouselController controller2;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller = useCarouselController();
          return Container();
        }),
      );

      expect(controller, isA<CarouselController>());

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller2 = useCarouselController();
          return Container();
        }),
      );

      expect(identical(controller, controller2), isTrue);
    });

    testWidgets('passes hook parameters to the CarouselController', (tester) async {
      late CarouselController controller;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            controller = useCarouselController(
              initialItem: 42,
            );

            return Container();
          },
        ),
      );

      expect(controller.initialItem, 42);
    });

    testWidgets('disposes the CarouselController on unmount', (tester) async {
      late CarouselController controller;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            controller = useCarouselController();
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
