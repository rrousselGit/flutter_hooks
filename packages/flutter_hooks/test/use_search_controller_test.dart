import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/src/framework.dart';
import 'package:flutter_hooks/src/hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useSearchController();

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
        ' │ useSearchController:\n'
        ' │   SearchController#00000(TextEditingValue(text: ┤├, selection:\n'
        ' │   TextSelection.invalid, composing: TextRange(start: -1, end:\n'
        ' │   -1)))\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  group('useSearchController', () {
    testWidgets('initial values matches with real constructor', (tester) async {
      late SearchController controller;
      final controller2 = SearchController();

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller = useSearchController();

          return Container();
        }),
      );

      expect(controller, isA<SearchController>());

      expect(controller.selection, controller2.selection);
      expect(controller.text, controller2.text);
      expect(controller.value, controller2.value);
    });

    testWidgets('check opening/closing view', (tester) async {
      late SearchController controller;

      await tester.pumpWidget(MaterialApp(
        home: HookBuilder(builder: (context) {
          controller = useSearchController();

          return SearchAnchor.bar(
            searchController: controller,
            suggestionsBuilder: (context, controller) => [],
          );
        }),
      ));

      controller.openView();

      expect(controller.isOpen, true);
       // Advance fade animation duration.
      await tester.pumpAndSettle(const Duration(seconds: 150));

      await tester.pumpWidget(MaterialApp(
        home: HookBuilder(builder: (context) {
          controller = useSearchController();

          return SearchAnchor.bar(
            searchController: controller,
            suggestionsBuilder: (context, controller) => [],
          );
        }),
      ));

      controller.closeView('selected');

      expect(controller.isOpen, false);
      expect(controller.text, 'selected');
    });
  });
}
