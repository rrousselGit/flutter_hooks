import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    final listenable = ValueNotifier(42);

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useOnListenableChange(listenable, () {});
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
        ' │ useOnListenableChange: ValueNotifier<int>#00000(42)\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  testWidgets('calls listener when Listenable updates', (tester) async {
    final listenable = ValueNotifier(42);

    int? value;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useOnListenableChange(
          listenable,
          () => value = listenable.value,
        );
        return const SizedBox();
      }),
    );

    expect(value, isNull);
    listenable.value++;
    expect(value, 43);
  });

  testWidgets(
    'listens new Listenable when Listenable is changed',
    (tester) => tester.runAsync(() async {
      final listenable1 = ValueNotifier(42);
      final listenable2 = ValueNotifier(42);

      await tester.pumpWidget(
        HookBuilder(
          key: const Key('hook_builder'),
          builder: (context) {
            useOnListenableChange(listenable1, () {});
            return const SizedBox();
          },
        ),
      );

      await tester.pumpWidget(
        HookBuilder(
          key: const Key('hook_builder'),
          builder: (context) {
            useOnListenableChange(listenable2, () {});
            return const SizedBox();
          },
        ),
      );

      // ignore: invalid_use_of_protected_member
      expect(listenable1.hasListeners, isFalse);
      // ignore: invalid_use_of_protected_member
      expect(listenable2.hasListeners, isTrue);
    }),
  );

  testWidgets('unsubscribes when listenable becomes null', (tester) async {
    final listenable = ValueNotifier(42);

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useOnListenableChange(listenable, () {});
        return const SizedBox();
      }),
    );

    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, isTrue);

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useOnListenableChange(null, () {});
        return const SizedBox();
      }),
    );

    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, isFalse);
  });
}
