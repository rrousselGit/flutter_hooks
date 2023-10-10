import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/src/framework.dart';
import 'package:flutter_hooks/src/hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useExpansionTileController();
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
        " │ useExpansionTileController: Instance of 'ExpansionTileController'\n"
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  group('useExpansionTileController', () {
    testWidgets('initial values matches with real constructor', (tester) async {
      late ExpansionTileController controller;
      final controller2 = ExpansionTileController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HookBuilder(builder: (context) {
            controller = useExpansionTileController();
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
      expect(controller, isA<ExpansionTileController>());
      expect(controller.isExpanded, controller2.isExpanded);
    });

    testWidgets('check expansion/collapse of tile', (tester) async {
      late ExpansionTileController controller;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HookBuilder(builder: (context) {
            controller = useExpansionTileController();
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
