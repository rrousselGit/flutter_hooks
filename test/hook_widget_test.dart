// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  final build = Func1<HookContext, int>();
  final dispose = Func0<void>();
  final initHook = Func0<void>();
  final didUpdateHook = Func1<HookTest, void>();
  final builder = Func1<HookContext, Widget>();

  final createHook = ({
    void mockDispose(),
  }) =>
      HookTest<int>(
          build: build.call,
          dispose: mockDispose ?? dispose.call,
          didUpdateHook: didUpdateHook.call,
          initHook: initHook.call);

  tearDown(() {
    reset(builder);
    reset(build);
    reset(dispose);
    reset(initHook);
    reset(didUpdateHook);
  });

  testWidgets('life-cycles in order', (tester) async {
    int result;
    HookTest<int> previousHook;

    when(build.call(any)).thenReturn(42);
    when(builder.call(any)).thenAnswer((invocation) {
      HookContext context = invocation.positionalArguments[0];
      previousHook = createHook();
      result = context.use(previousHook);
      return Container();
    });

    await tester.pumpWidget(HookBuilder(
      builder: builder.call,
    ));

    expect(result, 42);
    verifyInOrder([
      initHook.call(),
      build.call(any),
    ]);
    verifyZeroInteractions(didUpdateHook);
    verifyZeroInteractions(dispose);

    when(build.call(any)).thenReturn(24);
    await tester.pumpWidget(HookBuilder(
      builder: builder.call,
    ));

    expect(result, 24);
    verifyInOrder([
      // ignore: todo
      // TODO: previousHook instead of any
      didUpdateHook.call(any),
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

  testWidgets('dispose all called even on failed', (tester) async {
    final dispose2 = Func0<void>();

    when(build.call(any)).thenReturn(42);
    when(builder.call(any)).thenAnswer((invocation) {
      invocation.positionalArguments[0]
        ..use(createHook())
        ..use(createHook(mockDispose: dispose2));
      return Container();
    });

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    when(dispose.call()).thenThrow(24);
    await expectPump(
      () => tester.pumpWidget(const SizedBox()),
      throwsA(24),
    );

    verifyInOrder([
      dispose.call(),
      dispose2.call(),
    ]);
  });

  testWidgets('hook update with same instance do not call didUpdateHook',
      (tester) async {
    final hook = createHook();

    when(builder.call(any)).thenAnswer((invocation) {
      invocation.positionalArguments[0].use(hook);
      return Container();
    });

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyInOrder([
      initHook.call(),
      build.call(any),
    ]);
    verifyZeroInteractions(didUpdateHook);
    verifyZeroInteractions(dispose);

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyInOrder([
      build.call(any),
    ]);
    verifyNever(didUpdateHook.call(any));
    verifyNever(initHook.call());
    verifyNever(dispose.call());
  });

  testWidgets('rebuild with different hooks crash', (tester) async {
    when(builder.call(any)).thenAnswer((invocation) {
      invocation.positionalArguments[0].use(HookTest<int>());
      return Container();
    });

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    when(builder.call(any)).thenAnswer((invocation) {
      invocation.positionalArguments[0].use(HookTest<String>());
      return Container();
    });

    await expectPump(
      () => tester.pumpWidget(HookBuilder(builder: builder.call)),
      throwsAssertionError,
    );
  });
  testWidgets('rebuild added hooks crash', (tester) async {
    when(builder.call(any)).thenAnswer((invocation) {
      invocation.positionalArguments[0].use(HookTest<int>());
      return Container();
    });

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    when(builder.call(any)).thenAnswer((invocation) {
      invocation.positionalArguments[0].use(HookTest<int>());
      invocation.positionalArguments[0].use(HookTest<String>());
      return Container();
    });

    await expectPump(
      () => tester.pumpWidget(HookBuilder(builder: builder.call)),
      throwsAssertionError,
    );
  });

  testWidgets('rebuild removed hooks crash', (tester) async {
    when(builder.call(any)).thenAnswer((invocation) {
      invocation.positionalArguments[0].use(HookTest<int>());
      return Container();
    });

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    when(builder.call(any)).thenAnswer((invocation) {
      return Container();
    });

    await expectPump(
      () => tester.pumpWidget(HookBuilder(builder: builder.call)),
      throwsAssertionError,
    );
  });

  testWidgets('use call outside build crash', (tester) async {
    when(builder.call(any)).thenAnswer((invocation) => Container());

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    final context =
        tester.firstElement(find.byType(HookBuilder)) as HookElement;

    expect(() => context.use(HookTest<int>()), throwsAssertionError);
  });

  testWidgets('hot-reload triggers a build', (tester) async {
    int result;
    HookTest<int> previousHook;

    when(build.call(any)).thenReturn(42);
    when(builder.call(any)).thenAnswer((invocation) {
      HookContext context = invocation.positionalArguments[0];
      previousHook = createHook();
      result = context.use(previousHook);
      return Container();
    });

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    expect(result, 42);
    verifyInOrder([
      initHook.call(),
      build.call(any),
    ]);
    verifyZeroInteractions(didUpdateHook);
    verifyZeroInteractions(dispose);

    when(build.call(any)).thenReturn(24);

    hotReload(tester);
    await tester.pump();

    expect(result, 24);
    verifyInOrder([
      didUpdateHook.call(any),
      build.call(any),
    ]);
    verifyNever(initHook.call());
    verifyNever(dispose.call());
  });
}
