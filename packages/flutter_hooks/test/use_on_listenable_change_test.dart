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
    (tester) async {
      final listenable1 = ValueNotifier(42);
      final listenable2 = ValueNotifier(42);

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            useOnListenableChange(listenable1, () {});
            return const SizedBox();
          },
        ),
      );

      await tester.pumpWidget(
        HookBuilder(
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
    },
  );

  testWidgets(
    'listens new listener when listener is changed',
    (tester) async {
      final listenable = ValueNotifier(42);
      late final int value;

      void listener1() {
        throw StateError('listener1 should not have been called');
      }

      void listener2() {
        value = listenable.value;
      }

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            useOnListenableChange(listenable, listener1);
            return const SizedBox();
          },
        ),
      );

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            useOnListenableChange(listenable, listener2);
            return const SizedBox();
          },
        ),
      );

      listenable.value++;
      // By now, we should have subscribed to listener2, which sets the value
      expect(value, 43);
    },
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

  testWidgets('unsubscribes when disposed', (tester) async {
    final listenable = ValueNotifier(42);

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useOnListenableChange(listenable, () {});
        return const SizedBox();
      }),
    );

    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, isTrue);

    await tester.pumpWidget(Container());

    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, isFalse);
  });
}
