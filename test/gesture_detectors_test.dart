import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hooks/src/framework.dart';
import 'package:flutter_hooks/src/hooks.dart';

import 'mock.dart';

void main() {
  group('useTapGestureRecognizer', () {
    testWidgets('debugFillProperties', (tester) async {
      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          useTapGestureRecognizer();
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
          ' │ useTapGestureRecognizer: TapGestureRecognizer#00000\n'
          ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
        ),
      );
    });

    testWidgets("returns a TapGestureRecognizer that doesn't change",
        (tester) async {
      TapGestureRecognizer recognizer;
      TapGestureRecognizer recognizer2;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          recognizer = useTapGestureRecognizer();
          return const SizedBox();
        }),
      );

      expect(recognizer, isA<TapGestureRecognizer>());

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          recognizer2 = useTapGestureRecognizer();
          return const SizedBox();
        }),
      );

      expect(identical(recognizer, recognizer2), isTrue);
    });

    testWidgets('works in RichText for onTap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: HookBuilder(
            builder: (context) {
              final tapRecognizer = useTapGestureRecognizer()
                ..onTap = () => tapped = true;

              return Text.rich(TextSpan(
                text: 'This is some tappable test content.',
                recognizer: tapRecognizer,
              ));
            },
          ),
        ),
      );

      await tester.tap(find.byType(RichText));
      await tester.pump();

      expect(tapped, true);
    });
  });
}
