// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/hook.dart';

import 'mock.dart';

void main() {
  final build = Func1<HookContext, int>();
  final dispose = Func0<void>();
  final initHook = Func0<void>();
  final didUpdateHook = Func1<HookTest, void>();

  final createHook = (
    HookContext context, {
    void mockDispose(),
  }) =>
      HookTest<int>(
          build: build.call,
          dispose: mockDispose ?? dispose.call,
          didUpdateHook: didUpdateHook.call,
          initHook: initHook.call);

  tearDown(() {
    clearInteractions(build);
    clearInteractions(dispose);
    clearInteractions(initHook);
    clearInteractions(didUpdateHook);

    reset(build);
    reset(dispose);
    reset(initHook);
    reset(didUpdateHook);
  });

  testWidgets('life-cycles in order', (tester) async {
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
    final builder = Func1<HookContext, Widget>();
    final dispose2 = Func0<void>();
    final onError = Func1<FlutterErrorDetails, void>();

    when(build.call(any)).thenReturn(42);
    when(builder.call(any)).thenAnswer((invocation) {
      HookContext context = invocation.positionalArguments[0];
      context
        ..use(createHook(context))
        ..use(createHook(context, mockDispose: dispose2));
      return Container();
    });
    when(dispose.call()).thenThrow(42);

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    FlutterError.onError = onError.call;
    await tester.pumpWidget(const SizedBox());
    FlutterError.onError = FlutterError.dumpErrorToConsole;

    verifyInOrder([
      dispose.call(),
      onError.call(argThat(isInstanceOf<FlutterErrorDetails>())),
      dispose2.call(),
    ]);
  });

  testWidgets('hot-reload triggers a build', (tester) async {
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
