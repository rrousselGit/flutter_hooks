import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets(
    'should return same function when keys are not specified',
    (tester) async {
      late Function fn1;
      late Function fn2;

      await tester.pumpWidget(
        HookBuilder(
          key: const Key('hook_builder'),
          builder: (context) {
            fn1 = useCallback(() {});
            return Container();
          },
        ),
      );

      await tester.pumpWidget(
        HookBuilder(
          key: const Key('hook_builder'),
          builder: (context) {
            fn2 = useCallback(() {});
            return Container();
          },
        ),
      );

      expect(fn1, same(fn2));
    },
  );
}
