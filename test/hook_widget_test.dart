// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  final build = Func1<BuildContext, int>();
  final dispose = Func0<void>();
  final initHook = Func0<void>();
  final didUpdateHook = Func1<HookTest, void>();
  final builder = Func1<BuildContext, Widget>();

  final createHook = () => HookTest<int>(
        build: build.call,
        dispose: dispose.call,
        didUpdateHook: didUpdateHook.call,
        initHook: initHook.call,
      );

  tearDown(() {
    reset(builder);
    reset(build);
    reset(dispose);
    reset(initHook);
    reset(didUpdateHook);
  });

  testWidgets('hooks can be disposed independently with keys', (tester) async {
    List keys;
    List keys2;

    final dispose2 = Func0<void>();
    when(builder.call(any)).thenAnswer((invocation) {
      Hook.use(HookTest<int>(dispose: dispose.call, keys: keys));
      Hook.use(HookTest<String>(dispose: dispose2.call, keys: keys2));
      return Container();
    });
    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyZeroInteractions(dispose);
    verifyZeroInteractions(dispose2);

    keys = <dynamic>[];
    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verify(dispose.call()).called(1);
    verifyZeroInteractions(dispose2);

    keys2 = <dynamic>[];
    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verify(dispose2.call()).called(1);
    verifyNoMoreInteractions(dispose);
  });
  testWidgets('keys recreate hookstate', (tester) async {
    List keys;

    final createState = Func0<HookStateTest<int>>();
    when(createState.call()).thenReturn(HookStateTest<int>());

    when(builder.call(any)).thenAnswer((invocation) {
      Hook.use(HookTest<int>(
        build: build.call,
        dispose: dispose.call,
        didUpdateHook: didUpdateHook.call,
        initHook: initHook.call,
        keys: keys,
        createStateFn: createState.call,
      ));
      return Container();
    });
    await tester.pumpWidget(HookBuilder(builder: builder.call));

    final HookElement context = find.byType(HookBuilder).evaluate().first;

    verifyInOrder([
      createState.call(),
      initHook.call(),
      build.call(context),
    ]);
    verifyNoMoreInteractions(createState);
    verifyNoMoreInteractions(initHook);
    verifyNoMoreInteractions(build);
    verifyNoMoreInteractions(didUpdateHook);
    verifyNoMoreInteractions(dispose);

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyInOrder([
      didUpdateHook.call(any),
      build.call(context),
    ]);
    verifyNoMoreInteractions(createState);
    verifyNoMoreInteractions(initHook);
    verifyNoMoreInteractions(build);
    verifyNoMoreInteractions(didUpdateHook);
    verifyNoMoreInteractions(dispose);

    // from null to array
    keys = <dynamic>[];
    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyInOrder([
      dispose.call(),
      createState.call(),
      initHook.call(),
      build.call(context)
    ]);
    verifyNoMoreInteractions(createState);
    verifyNoMoreInteractions(initHook);
    verifyNoMoreInteractions(build);
    verifyNoMoreInteractions(didUpdateHook);
    verifyNoMoreInteractions(dispose);

    // array immutable
    keys.add(42);

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyInOrder([
      didUpdateHook.call(any),
      build.call(context),
    ]);
    verifyNoMoreInteractions(createState);
    verifyNoMoreInteractions(initHook);
    verifyNoMoreInteractions(build);
    verifyNoMoreInteractions(didUpdateHook);
    verifyNoMoreInteractions(dispose);

    // new array but content equal
    keys = <dynamic>[42];

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyInOrder([
      didUpdateHook.call(any),
      build.call(context),
    ]);
    verifyNoMoreInteractions(createState);
    verifyNoMoreInteractions(initHook);
    verifyNoMoreInteractions(build);
    verifyNoMoreInteractions(didUpdateHook);
    verifyNoMoreInteractions(dispose);

    // new array new content
    keys = <dynamic>[44];

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyInOrder([
      dispose.call(),
      createState.call(),
      initHook.call(),
      build.call(context)
    ]);
    verifyNoMoreInteractions(createState);
    verifyNoMoreInteractions(initHook);
    verifyNoMoreInteractions(build);
    verifyNoMoreInteractions(didUpdateHook);
    verifyNoMoreInteractions(dispose);
  });

  testWidgets('hook & setState', (tester) async {
    final setState = Func0<void>();
    final hook = MyHook();
    HookElement hookContext;
    MyHookState state;

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        hookContext = context as HookElement;
        state = Hook.use(hook);
        return Container();
      },
    ));

    expect(state.hook, hook);
    expect(state.context, hookContext);
    expect(hookContext.dirty, false);

    state.setState(setState.call);
    verify(setState.call()).called(1);

    expect(hookContext.dirty, true);
  });

  testWidgets('life-cycles in order', (tester) async {
    int result;
    HookTest<int> hook;

    when(build.call(any)).thenReturn(42);
    when(builder.call(any)).thenAnswer((invocation) {
      hook = createHook();
      result = Hook.use(hook);
      return Container();
    });

    await tester.pumpWidget(HookBuilder(
      builder: builder.call,
    ));

    final context = tester.firstElement(find.byType(HookBuilder));
    expect(result, 42);
    verifyInOrder([
      initHook.call(),
      build.call(context),
    ]);
    verifyZeroInteractions(didUpdateHook);
    verifyZeroInteractions(dispose);

    when(build.call(context)).thenReturn(24);
    var previousHook = hook;

    await tester.pumpWidget(HookBuilder(
      builder: builder.call,
    ));

    expect(result, 24);
    verifyInOrder([
      didUpdateHook.call(previousHook),
      build.call(any),
    ]);
    verifyNoMoreInteractions(initHook);
    verifyZeroInteractions(dispose);

    previousHook = hook;
    await tester.pump();

    verifyNoMoreInteractions(initHook);
    verifyNoMoreInteractions(didUpdateHook);
    verifyNoMoreInteractions(build);
    verifyZeroInteractions(dispose);

    await tester.pumpWidget(const SizedBox());

    verifyNoMoreInteractions(initHook);
    verifyNoMoreInteractions(didUpdateHook);
    verifyNoMoreInteractions(build);
    verify(dispose.call());
    verifyNoMoreInteractions(dispose);
  });

  testWidgets('dispose all called even on failed', (tester) async {
    final dispose2 = Func0<void>();

    when(build.call(any)).thenReturn(42);
    when(builder.call(any)).thenAnswer((invocation) {
      Hook.use(createHook());
      Hook.use(HookTest<int>(dispose: dispose2));
      return Container();
    });

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    when(dispose.call()).thenThrow(24);
    await tester.pumpWidget(const SizedBox());

    expect(tester.takeException(), 24);

    verifyInOrder([
      dispose.call(),
      dispose2.call(),
    ]);
  });

  testWidgets('hook update with same instance do not call didUpdateHook',
      (tester) async {
    final hook = createHook();

    when(builder.call(any)).thenAnswer((invocation) {
      Hook.use(hook);
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
      Hook.use(HookTest<int>());
      return Container();
    });

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    when(builder.call(any)).thenAnswer((invocation) {
      Hook.use(HookTest<String>());
      return Container();
    });

    await expectPump(
      () => tester.pumpWidget(HookBuilder(builder: builder.call)),
      throwsAssertionError,
    );
  });
  testWidgets('rebuild added hooks crash', (tester) async {
    when(builder.call(any)).thenAnswer((invocation) {
      Hook.use(HookTest<int>());
      return Container();
    });

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    when(builder.call(any)).thenAnswer((invocation) {
      Hook.use(HookTest<int>());
      Hook.use(HookTest<String>());
      return Container();
    });

    await tester.pumpWidget(HookBuilder(builder: builder.call));
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('rebuild removed hooks crash', (tester) async {
    when(builder.call(any)).thenAnswer((invocation) {
      Hook.use(HookTest<int>());
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

    expect(() => Hook.use(HookTest<int>()), throwsAssertionError);
  });

  testWidgets('hot-reload triggers a build', (tester) async {
    int result;
    HookTest<int> previousHook;

    when(build.call(any)).thenReturn(42);
    when(builder.call(any)).thenAnswer((invocation) {
      previousHook = createHook();
      result = Hook.use(previousHook);
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

  testWidgets('hot-reload can add hooks at the end of the list',
      (tester) async {
    HookTest hook1;

    final dispose2 = Func0<void>();
    final initHook2 = Func0<void>();
    final didUpdateHook2 = Func1<HookTest, void>();
    final build2 = Func1<BuildContext, String>();

    when(builder.call(any)).thenAnswer((invocation) {
      Hook.use(hook1 = createHook());
      return Container();
    });

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    final HookElement context = find.byType(HookBuilder).evaluate().first;

    verifyInOrder([
      initHook.call(),
      build.call(context),
    ]);
    verifyZeroInteractions(dispose);
    verifyZeroInteractions(didUpdateHook);

    when(builder.call(any)).thenAnswer((invocation) {
      Hook.use(createHook());
      Hook.use(HookTest<String>(
        initHook: initHook2,
        build: build2,
        didUpdateHook: didUpdateHook2,
        dispose: dispose2,
      ));
      return Container();
    });

    hotReload(tester);
    await tester.pump();

    verifyInOrder([
      didUpdateHook.call(hook1),
      build.call(context),
      initHook2.call(),
      build2.call(context),
    ]);
    verifyNoMoreInteractions(initHook);
    verifyZeroInteractions(dispose);
    verifyZeroInteractions(dispose2);
    verifyZeroInteractions(didUpdateHook2);
  });

  testWidgets('hot-reload can add hooks in the middle of the list',
      (tester) async {
    final dispose2 = Func0<void>();
    final initHook2 = Func0<void>();
    final didUpdateHook2 = Func1<HookTest, void>();
    final build2 = Func1<BuildContext, String>();

    when(builder.call(any)).thenAnswer((invocation) {
      Hook.use(createHook());
      return Container();
    });

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    final HookElement context = find.byType(HookBuilder).evaluate().first;

    verifyInOrder([
      initHook.call(),
      build.call(context),
    ]);
    verifyZeroInteractions(dispose);
    verifyZeroInteractions(didUpdateHook);

    when(builder.call(any)).thenAnswer((invocation) {
      Hook.use(HookTest<String>(
        initHook: initHook2,
        build: build2,
        didUpdateHook: didUpdateHook2,
        dispose: dispose2,
      ));
      Hook.use(createHook());
      return Container();
    });

    hotReload(tester);
    await tester.pump();

    verifyInOrder([
      dispose.call(),
      initHook2.call(),
      build2.call(context),
      initHook.call(),
      build.call(context),
    ]);
    verifyNoMoreInteractions(didUpdateHook);
    verifyNoMoreInteractions(dispose);
    verifyZeroInteractions(dispose2);
    verifyZeroInteractions(didUpdateHook2);
  });
  testWidgets('hot-reload can remove hooks', (tester) async {
    final dispose2 = Func0<void>();
    final initHook2 = Func0<void>();
    final didUpdateHook2 = Func1<HookTest, void>();
    final build2 = Func1<BuildContext, int>();

    when(builder.call(any)).thenAnswer((invocation) {
      Hook.use(createHook());
      Hook.use(HookTest<int>(
        initHook: initHook2,
        build: build2,
        didUpdateHook: didUpdateHook2,
        dispose: dispose2,
      ));
      return Container();
    });

    await tester.pumpWidget(HookBuilder(builder: builder.call));
    final HookElement context = find.byType(HookBuilder).evaluate().first;

    verifyInOrder([
      initHook.call(),
      build.call(context),
      initHook2.call(),
      build2.call(context),
    ]);

    verifyZeroInteractions(dispose);
    verifyZeroInteractions(didUpdateHook);
    verifyZeroInteractions(dispose2);
    verifyZeroInteractions(didUpdateHook2);

    when(builder.call(any)).thenAnswer((invocation) {
      return Container();
    });

    hotReload(tester);
    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyInOrder([
      dispose.call(),
      dispose2.call(),
    ]);

    verifyNoMoreInteractions(initHook);
    verifyNoMoreInteractions(initHook2);
    verifyNoMoreInteractions(build2);
    verifyNoMoreInteractions(build);

    verifyZeroInteractions(didUpdateHook);
    verifyZeroInteractions(didUpdateHook2);
  });
  testWidgets('hot-reload disposes hooks when type change', (tester) async {
    HookTest hook1;

    final dispose2 = Func0<void>();
    final initHook2 = Func0<void>();
    final didUpdateHook2 = Func1<HookTest, void>();
    final build2 = Func1<BuildContext, int>();

    final dispose3 = Func0<void>();
    final initHook3 = Func0<void>();
    final didUpdateHook3 = Func1<HookTest, void>();
    final build3 = Func1<BuildContext, int>();

    final dispose4 = Func0<void>();
    final initHook4 = Func0<void>();
    final didUpdateHook4 = Func1<HookTest, void>();
    final build4 = Func1<BuildContext, int>();

    when(builder.call(any)).thenAnswer((invocation) {
      Hook.use(hook1 = createHook());
      Hook.use(HookTest<String>(dispose: dispose2));
      Hook.use(HookTest<Object>(dispose: dispose3));
      Hook.use(HookTest<void>(dispose: dispose4));
      return Container();
    });

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    final HookElement context = find.byType(HookBuilder).evaluate().first;

    // We don't care about datas of the first render
    clearInteractions(initHook);
    clearInteractions(didUpdateHook);
    clearInteractions(dispose);
    clearInteractions(build);

    clearInteractions(initHook2);
    clearInteractions(didUpdateHook2);
    clearInteractions(dispose2);
    clearInteractions(build2);

    clearInteractions(initHook3);
    clearInteractions(didUpdateHook3);
    clearInteractions(dispose3);
    clearInteractions(build3);

    clearInteractions(initHook4);
    clearInteractions(didUpdateHook4);
    clearInteractions(dispose4);
    clearInteractions(build4);

    when(builder.call(any)).thenAnswer((invocation) {
      Hook.use(createHook());
      // changed type from HookTest<String>
      Hook.use(HookTest<int>(
        initHook: initHook2,
        build: build2,
        didUpdateHook: didUpdateHook2,
      ));
      Hook.use(HookTest<int>(
        initHook: initHook3,
        build: build3,
        didUpdateHook: didUpdateHook3,
      ));
      Hook.use(HookTest<int>(
        initHook: initHook4,
        build: build4,
        didUpdateHook: didUpdateHook4,
      ));
      return Container();
    });

    hotReload(tester);
    await tester.pump();

    verifyInOrder([
      didUpdateHook.call(hook1),
      build.call(context),
      dispose2.call(),
      initHook2.call(),
      build2.call(context),
      dispose3.call(),
      initHook3.call(),
      build3.call(context),
      dispose4.call(),
      initHook4.call(),
      build4.call(context),
    ]);
    verifyZeroInteractions(initHook);
    verifyZeroInteractions(dispose);
    verifyZeroInteractions(didUpdateHook2);
    verifyZeroInteractions(didUpdateHook3);
    verifyZeroInteractions(didUpdateHook4);
  });

  testWidgets('hot-reload disposes hooks when type change', (tester) async {
    HookTest hook1;

    final dispose2 = Func0<void>();
    final initHook2 = Func0<void>();
    final didUpdateHook2 = Func1<HookTest, void>();
    final build2 = Func1<BuildContext, int>();

    final dispose3 = Func0<void>();
    final initHook3 = Func0<void>();
    final didUpdateHook3 = Func1<HookTest, void>();
    final build3 = Func1<BuildContext, int>();

    final dispose4 = Func0<void>();
    final initHook4 = Func0<void>();
    final didUpdateHook4 = Func1<HookTest, void>();
    final build4 = Func1<BuildContext, int>();

    when(builder.call(any)).thenAnswer((invocation) {
      Hook.use(hook1 = createHook());
      Hook.use(HookTest<String>(dispose: dispose2));
      Hook.use(HookTest<Object>(dispose: dispose3));
      Hook.use(HookTest<void>(dispose: dispose4));
      return Container();
    });

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    final HookElement context = find.byType(HookBuilder).evaluate().first;

    // We don't care about datas of the first render
    clearInteractions(initHook);
    clearInteractions(didUpdateHook);
    clearInteractions(dispose);
    clearInteractions(build);

    clearInteractions(initHook2);
    clearInteractions(didUpdateHook2);
    clearInteractions(dispose2);
    clearInteractions(build2);

    clearInteractions(initHook3);
    clearInteractions(didUpdateHook3);
    clearInteractions(dispose3);
    clearInteractions(build3);

    clearInteractions(initHook4);
    clearInteractions(didUpdateHook4);
    clearInteractions(dispose4);
    clearInteractions(build4);

    when(builder.call(any)).thenAnswer((invocation) {
      Hook.use(createHook());
      // changed type from HookTest<String>
      Hook.use(HookTest<int>(
        initHook: initHook2,
        build: build2,
        didUpdateHook: didUpdateHook2,
      ));
      Hook.use(HookTest<int>(
        initHook: initHook3,
        build: build3,
        didUpdateHook: didUpdateHook3,
      ));
      Hook.use(HookTest<int>(
        initHook: initHook4,
        build: build4,
        didUpdateHook: didUpdateHook4,
      ));
      return Container();
    });

    hotReload(tester);
    await tester.pump();

    verifyInOrder([
      didUpdateHook.call(hook1),
      build.call(context),
      dispose2.call(),
      initHook2.call(),
      build2.call(context),
      dispose3.call(),
      initHook3.call(),
      build3.call(context),
      dispose4.call(),
      initHook4.call(),
      build4.call(context),
    ]);
    verifyZeroInteractions(initHook);
    verifyZeroInteractions(dispose);
    verifyZeroInteractions(didUpdateHook2);
    verifyZeroInteractions(didUpdateHook3);
    verifyZeroInteractions(didUpdateHook4);
  });

  testWidgets('hot-reload without hooks do not crash', (tester) async {
    when(builder.call(any)).thenAnswer((invocation) {
      return Container();
    });

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    hotReload(tester);
    await expectPump(() => tester.pump(), completes);
  });
}

class MyHook extends Hook<MyHookState> {
  @override
  MyHookState createState() => MyHookState();
}

class MyHookState extends HookState<MyHookState, MyHook> {
  @override
  MyHookState build(BuildContext context) {
    return this;
  }
}
