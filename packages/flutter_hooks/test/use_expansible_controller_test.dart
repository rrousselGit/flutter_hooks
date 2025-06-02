import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/src/framework.dart';
import 'package:flutter_hooks/src/hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useExpansibleController();
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
        " │ useExpansibleController: Instance of 'ExpansibleController'\n"
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  group('useExpansibleController', () {
    testWidgets('initial values matches with real constructor', (tester) async {
      late ExpansibleController controller;
      final controller2 = ExpansibleController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HookBuilder(builder: (context) {
            controller = useExpansibleController();
            return Column(
              children: [
                ExpansionTile(
                  controller: controller,
                  title: const Text('Expansion Tile'),
                ),
                ExpansionTile(
                  controller: controller2,
                  title: const Text('Expansion Tile 2'),
                ),
              ],
            );
          }),
        ),
      ));
      expect(controller, isA<ExpansibleController>());
      expect(controller.isExpanded, controller2.isExpanded);
    });

    testWidgets('check expansion/collapse of tile', (tester) async {
      late ExpansibleController controller;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HookBuilder(builder: (context) {
            controller = useExpansibleController();
            return ExpansionTile(
              controller: controller,
              title: const Text('Expansion Tile'),
            );
          }),
        ),
      ));

      expect(controller.isExpanded, false);
      controller.expand();
      expect(controller.isExpanded, true);
      controller.collapse();
      expect(controller.isExpanded, false);
    });
  });
}
