import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('useCallback', (tester) async {
    late int Function() fn;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        fn = useCallback<int Function()>(() => 42, []);
        return Container();
      }),
    );

    expect(fn(), 42);

    late int Function() fn2;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        fn2 = useCallback<int Function()>(() => 42, []);
        return Container();
      }),
    );

    expect(fn2, fn);

    late int Function() fn3;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        fn3 = useCallback<int Function()>(() => 21, [42]);
        return Container();
      }),
    );

    expect(fn3, isNot(fn));
    expect(fn3(), 21);
  });

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
