import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/src/framework.dart';
import 'package:flutter_hooks/src/hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useDraggableScrollableController();
        return const SizedBox();
      }),
    );

    await tester.pump();

    final element = tester.element(find.byType(HookBuilder));

    expect(
      element
          .toDiagnosticsNode(style: DiagnosticsTreeStyle.offstage)
          .toStringDeep(),
      equalsIgnoringHashCodes('HookBuilder\n'
          ' │ useDraggableScrollableController: Instance of\n'
          " │   'DraggableScrollableController'\n"
          ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n'),
    );
  });

  group('useDraggableScrollableController', () {
    testWidgets(
        'controller functions correctly and initial values matches with real constructor',
        (tester) async {
      late DraggableScrollableController controller;
      final controller2 = DraggableScrollableController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HookBuilder(builder: (context) {
            return Column(
              children: [
                ElevatedButton(
                    onPressed: () {
                      showBottomSheet(
                          context: context,
                          builder: (context) {
                            // Using a builder here to ensure that the controller is
                            // disposed when the sheet is closed.
                            return HookBuilder(builder: (context) {
                              controller = useDraggableScrollableController();
                              return DraggableScrollableSheet(
                                controller: controller,
                                builder: (context, scrollController) {
                                  return ListView.builder(
                                    controller: scrollController,
                                    itemCount: 100,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                        title: Text('Item $index on Sheet 1'),
                                      );
                                    },
                                  );
                                },
                              );
                            });
                          });
                    },
                    child: Text("Open Sheet 1")),
                ElevatedButton(
                    onPressed: () {
                      showBottomSheet(
                          context: context,
                          builder: (context) {
                            return DraggableScrollableSheet(
                              controller: controller2,
                              builder: (context, scrollController) {
                                return ListView.builder(
                                  controller: scrollController,
                                  itemCount: 100,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text('Item $index on Sheet 2'),
                                    );
                                  },
                                );
                              },
                            );
                          });
                    },
                    child: Text("Open Sheet 2"))
              ],
            );
          }),
        ),
      ));

      // Open Sheet 1 and get the initial values
      await tester.tap(find.text('Open Sheet 1'));
      await tester.pumpAndSettle();
      final controllerPixels = controller.pixels;
      final controllerSize = controller.size;
      final controllerIsAttached = controller.isAttached;
      // Close Sheet 1 by dragging it down
      await tester.fling(
          find.byType(DraggableScrollableSheet), const Offset(0, 500), 300);
      await tester.pumpAndSettle();

      // Open Sheet 2 and get the initial values
      await tester.tap(find.text('Open Sheet 2'));
      await tester.pumpAndSettle();
      final controller2Pixels = controller2.pixels;
      final controller2Size = controller2.size;
      final controller2IsAttached = controller2.isAttached;
      // Close Sheet 2 by dragging it down
      await tester.fling(
          find.byType(DraggableScrollableSheet), const Offset(0, 500), 300);
      await tester.pumpAndSettle();

      // Compare the initial values of the two controllers
      expect(controllerPixels, controller2Pixels);
      expect(controllerSize, controller2Size);
      expect(controllerIsAttached, controller2IsAttached);

      // Open Sheet 1 again and use the controller to scroll
      await tester.tap(find.text('Open Sheet 1'));
      await tester.pumpAndSettle();
      const targetSize = 1.0;
      controller.jumpTo(targetSize);
      expect(targetSize, controller.size);
    });
  });
}
