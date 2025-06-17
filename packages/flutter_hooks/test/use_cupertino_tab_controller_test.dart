import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/src/framework.dart';
import 'package:flutter_hooks/src/hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useCupertinoTabController();
        return const SizedBox();
      }),
    );

    await tester.pump();

    final element = tester.element(find.byType(HookBuilder));

    expect(
      element
          .toDiagnosticsNode(style: DiagnosticsTreeStyle.offstage)
          .toStringDeep(),
      equalsIgnoringHashCodes(
        'HookBuilder\n'
        " │ useCupertinoTabController: Instance of 'CupertinoTabController'\n"
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  group('useCupertinoCupertinoCupertinoTabController', () {
    testWidgets('initial values matches with real constructor', (tester) async {
      late CupertinoTabController controller;
      late CupertinoTabController controller2;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller2 = CupertinoTabController();
          controller = useCupertinoTabController();
          return Container();
        }),
      );

      expect(controller.index, controller2.index);
    });
    testWidgets("returns a CupertinoTabController that doesn't change",
        (tester) async {
      late CupertinoTabController controller;
      late CupertinoTabController controller2;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller = useCupertinoTabController(initialIndex: 1);
          return Container();
        }),
      );

      expect(controller, isA<CupertinoTabController>());

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller2 = useCupertinoTabController(initialIndex: 1);
          return Container();
        }),
      );

      expect(identical(controller, controller2), isTrue);
    });

    testWidgets('passes hook parameters to the CupertinoTabController',
        (tester) async {
      late CupertinoTabController controller;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            controller = useCupertinoTabController(initialIndex: 2);

            return Container();
          },
        ),
      );

      expect(controller.index, 2);
    });
  });
}
