import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/src/framework.dart';
import 'package:flutter_hooks/src/hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useTreeSliverController();
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
        " │ useTreeSliverController: Instance of 'TreeSliverController'\n"
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  group('useTreeSliverController', () {
    testWidgets('check expansion/collapse of node', (tester) async {
      late TreeSliverController controller;
      final tree = <TreeSliverNode<int>>[
        TreeSliverNode(0, children: [TreeSliverNode(1), TreeSliverNode(2)]),
        TreeSliverNode(
            expanded: true, 3, children: [TreeSliverNode(4), TreeSliverNode(5)])
      ];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HookBuilder(builder: (context) {
            controller = useTreeSliverController();
            return CustomScrollView(slivers: [
              TreeSliver(
                controller: controller,
                tree: tree,
              ),
            ]);
          }),
        ),
      ));

      expect(controller.isExpanded(tree[0]), false);
      controller.expandNode(tree[0]);
      expect(controller.isExpanded(tree[0]), true);
      controller.collapseNode(tree[0]);
      expect(controller.isExpanded(tree[0]), false);

      expect(controller.isExpanded(tree[1]), true);
      controller.collapseNode(tree[1]);
      expect(controller.isExpanded(tree[1]), false);
      controller.expandNode(tree[1]);
      expect(controller.isExpanded(tree[1]), true);
    });
  });
}
