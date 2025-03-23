import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/src/framework.dart';
import 'package:flutter_hooks/src/hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useSnapshotController();
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
        " │ useSnapshotController: Instance of 'SnapshotController'\n"
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  group('useSnapshotController', () {
    testWidgets('initial values matches with real constructor', (tester) async {
      late SnapshotController controller;
      late SnapshotController controller2;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller2 = SnapshotController();
          controller = useSnapshotController();
          return Container();
        }),
      );

      expect(controller.allowSnapshotting, controller2.allowSnapshotting);
    });

    testWidgets('passes hook parameters to the SnapshotController',
        (tester) async {
      late SnapshotController controller;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller = useSnapshotController(allowSnapshotting: true);
          return const SizedBox();
        }),
      );

      expect(controller.allowSnapshotting, true);

      late SnapshotController retrievedController;
      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          // ignore: avoid_redundant_argument_values
          retrievedController = useSnapshotController(allowSnapshotting: false);
          return const SizedBox();
        }),
      );

      expect(retrievedController, same(controller));
      expect(retrievedController.allowSnapshotting, false);
    });
  });
}
