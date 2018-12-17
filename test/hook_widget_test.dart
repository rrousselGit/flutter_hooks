// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/hook.dart';

import 'mock.dart';

void main() {
  final build = Func1<HookContext, int>();
  final dispose = Func0<void>();
  final initHook = Func0<void>();
  final didUpdateHook = Func1<HookTest, void>();

  final createHook = (HookContext context) => HookTest<int>(
      build: build.call,
      dispose: dispose.call,
      didUpdateHook: didUpdateHook.call,
      initHook: initHook.call);

  tearDown(() {
    clearInteractions(build);
    clearInteractions(dispose);
    clearInteractions(initHook);
    clearInteractions(didUpdateHook);
  });

  group('life-cycles', () {
    testWidgets('classic', (tester) async {
      final builder = Func1<HookContext, Widget>();
      int result;
      HookTest<int> previousHook;

      when(build.call(any)).thenReturn(42);
      when(builder.call(any)).thenAnswer((invocation) {
        HookContext context = invocation.positionalArguments[0];
        previousHook = createHook(context);
        result = context.use(previousHook);
        return Container();
      });

      await tester.pumpWidget(HookBuilder(
        builder: builder.call,
      ));

      expect(result, 42);
      verifyInOrder<dynamic>([
        initHook.call() as dynamic,
        build.call(any),
      ]);
      verifyZeroInteractions(didUpdateHook);
      verifyZeroInteractions(dispose);

      when(build.call(any)).thenReturn(24);
      await tester.pumpWidget(HookBuilder(
        builder: builder.call,
      ));

      expect(result, 24);
      verifyInOrder<dynamic>([
        // TODO: previousHook instead of any
        didUpdateHook.call(any) as dynamic,
        build.call(any),
      ]);
      verifyNever(initHook.call());
      verifyZeroInteractions(dispose);

      await tester.pump();

      verifyNever(initHook.call());
      verifyNever(didUpdateHook.call(any));
      verifyNever(build.call(any));
      verifyZeroInteractions(dispose);

      await tester.pumpWidget(const SizedBox());

      verifyNever(initHook.call());
      verifyNever(didUpdateHook.call(any));
      verifyNever(build.call(any));
      verify(dispose.call());
    });
  });
}
