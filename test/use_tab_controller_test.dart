import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hooks/src/framework.dart';
import 'package:flutter_hooks/src/hooks.dart';

void main() {
  group('useTabController', () {
    testWidgets("returns a TabController that doesn't change", (tester) async {
      final rebuilder = ValueNotifier(0);
      TabController controller;

      await tester.pumpWidget(HookBuilder(
        builder: (context) {
          controller = useTabController(length: 1);

          useValueNotifier(rebuilder);

          return const SizedBox();
        },
      ));

      expect(controller, isA<TabController>());

      final oldController = controller;
      rebuilder.notifyListeners();
      await tester.pumpAndSettle();

      expect(identical(controller, oldController), isTrue);
    });

    testWidgets('passes hook parameters to the TabController', (tester) async {
      TabController controller;

      await tester.pumpWidget(HookBuilder(
        builder: (context) {
          controller = useTabController(
            initialIndex: 2,
            length: 4,
          );

          return const SizedBox();
        },
      ));

      expect(controller.index, 2);
      expect(controller.length, 4);
    });
  });
}
