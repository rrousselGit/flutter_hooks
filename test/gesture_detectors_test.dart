import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hooks/src/framework.dart';
import 'package:flutter_hooks/src/hooks.dart';

import 'mock.dart';

void _testGestureRecognizer<T>({
  Type gestureRecognizer,
  T Function() useHook,
}) {
  group('use$gestureRecognizer', () {
    testWidgets('debugFillProperties', (tester) async {
      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          useHook();
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
          ' │ use$T: $T#00000\n'
          ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
        ),
      );
    });

    testWidgets("returns a $T that doesn't change", (tester) async {
      T recognizer;
      T recognizer2;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          recognizer = useHook();
          return const SizedBox();
        }),
      );

      expect(recognizer, isA<T>());

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          recognizer2 = useHook();
          return const SizedBox();
        }),
      );

      expect(identical(recognizer, recognizer2), isTrue);
    });
  });
}

void main() {
  _testGestureRecognizer(
    gestureRecognizer: TapGestureRecognizer,
    useHook: useTapGestureRecognizer,
  );
}
