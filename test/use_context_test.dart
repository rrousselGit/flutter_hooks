import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock.dart';

void main() {
  group('useContext', () {
    testWidgets('returns current BuildContext during build', (tester) async {
      BuildContext res;

      await tester.pumpWidget(HookBuilder(builder: (context, h) {
        res = h.useContext();
        return Container();
      }));

      final context = tester.firstElement(find.byType(HookBuilder));

      expect(res, context);
    });

    testWidgets('crashed outside of build', (tester) async {
      const Hookable h = null;
      expect(h.useContext, throwsAssertionError);
      await tester.pumpWidget(HookBuilder(
        builder: (context, h) {
          h.useContext();
          return Container();
        },
      ));
      expect(h.useContext, throwsAssertionError);
    });
  });
}
