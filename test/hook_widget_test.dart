// ignore_for_file: invalid_use_of_protected_member, only_throw_errors
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

class InheritedInitHook extends Hook<void> {
  @override
  InheritedInitHookState createState() => InheritedInitHookState();
}

class InheritedInitHookState extends HookState<void, InheritedInitHook> {
  @override
  void initHook() {
    context.dependOnInheritedWidgetOfExactType<InheritedWidget>();
  }

  @override
  void build(BuildContext context) {}
}

void main() {
  final build = Func1<BuildContext, int>();
  final dispose = Func0<void>();
  final deactivate = Func0<void>();
  final initHook = Func0<void>();
  final didUpdateHook = Func1<HookTest, void>();
  final didBuild = Func0<void>();
  final reassemble = Func0<void>();
  final builder = Func1<BuildContext, Widget>();

  HookTest<int> createHook() {
    return HookTest<int>(
      build: build.call,
      dispose: dispose.call,
      didUpdateHook: didUpdateHook.call,
      reassemble: reassemble.call,
      initHook: initHook.call,
      didBuild: didBuild,
      deactivate: deactivate,
    );
  }

  void verifyNoMoreHookInteration() {
    verifyNoMoreInteractions(build);
    verifyNoMoreInteractions(didBuild);
    verifyNoMoreInteractions(dispose);
    verifyNoMoreInteractions(initHook);
    verifyNoMoreInteractions(didUpdateHook);
  }

  tearDown(() {
    reset(builder);
    reset(build);
    reset(didBuild);
    reset(dispose);
    reset(deactivate);
    reset(initHook);
    reset(didUpdateHook);
    reset(reassemble);
  });

  testWidgets('StatefulHookWidget', (tester) async {
    final notifier = ValueNotifier(0);

    await tester.pumpWidget(MyStatefulHook(value: 0, notifier: notifier));

    expect(find.text('0 0'), findsOneWidget);

    await tester.pumpWidget(MyStatefulHook(value: 1, notifier: notifier));

    expect(find.text('1 0'), findsOneWidget);

    notifier.value++;
    await tester.pump();

    expect(find.text('1 1'), findsOneWidget);
  });

  testWidgets(
      'should call deactivate when removed from and inserted into another place',
      (tester) async {
    final _key1 = GlobalKey();
    final _key2 = GlobalKey();
    final state = ValueNotifier(false);
    final deactivate1 = Func0<void>();
    final deactivate2 = Func0<void>();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: ValueListenableBuilder<bool>(
          valueListenable: state,
          builder: (context, value, _) {
            return Stack(children: [
              Container(
                key: const Key('1'),
                child: HookBuilder(
                  key: value ? _key2 : _key1,
                  builder: (context) {
                    Hook.use(HookTest<int>(deactivate: deactivate1));
                    return Container();
                  },
                ),
              ),
              HookBuilder(
                key: !value ? _key2 : _key1,
                builder: (context) {
                  Hook.use(HookTest<int>(deactivate: deactivate2));
                  return Container();
                },
              ),
            ]);
          },
        ),
      ),
    );

    await tester.pump();

    verifyNever(deactivate1());
    verifyNever(deactivate2());
    state.value = true;

    await tester.pump();

    verifyInOrder([
      deactivate1.call(),
      deactivate2.call(),
    ]);

    await tester.pump();

    verifyNoMoreInteractions(deactivate1);
    verifyNoMoreInteractions(deactivate2);
  });

  testWidgets('should call other deactivates even if one fails',
      (tester) async {
    final onError = Func1<FlutterErrorDetails, void>();
    final oldOnError = FlutterError.onError;
    FlutterError.onError = onError;

    final errorBuilder = ErrorWidget.builder;
    ErrorWidget.builder = Func1<FlutterErrorDetails, Widget>();
    when(ErrorWidget.builder(any)).thenReturn(Container());

    final deactivate = Func0<void>();
    when(deactivate.call()).thenThrow(42);
    final deactivate2 = Func0<void>();

    final _key = GlobalKey();

    final widget = HookBuilder(
      key: _key,
      builder: (context) {
        Hook.use(HookTest<int>(deactivate: deactivate));
        Hook.use(HookTest<int>(deactivate: deactivate2));
        return Container();
      },
    );

    try {
      await tester.pumpWidget(SizedBox(child: widget));

      verifyNoMoreInteractions(deactivate);
      verifyNoMoreInteractions(deactivate2);

      await tester.pumpWidget(widget);

      verifyInOrder([
        deactivate(),
        deactivate2(),
      ]);

      verify(onError.call(any)).called(1);
      verifyNoMoreInteractions(deactivate);
      verifyNoMoreInteractions(deactivate2);
    } finally {
      // reset the exception because after the test
      // flutter tries to deactivate the widget and it causes
      // and exception
      when(deactivate.call()).thenAnswer((_) {});
      FlutterError.onError = oldOnError;
      ErrorWidget.builder = errorBuilder;
    }
  });

  testWidgets('should not allow using inheritedwidgets inside initHook',
      (tester) async {
    await tester.pumpWidget(HookBuilder(builder: (_) {
      Hook.use(InheritedInitHook());
      return Container();
    }));

    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('allows using inherited widgets outside of initHook',
      (tester) async {
    when(build(any)).thenAnswer((invocation) {
      final context = invocation.positionalArguments.first as BuildContext;
      context.dependOnInheritedWidgetOfExactType<InheritedWidget>();
      return null;
    });

    await tester.pumpWidget(HookBuilder(builder: (_) {
      Hook.use(HookTest<void>(build: build));
      return Container();
    }));
  });
  testWidgets("release mode don't crash", (tester) async {
    ValueNotifier<int> notifier;
    debugHotReloadHooksEnabled = false;
    addTearDown(() => debugHotReloadHooksEnabled = true);

    await tester.pumpWidget(HookBuilder(builder: (_) {
      notifier = useState(0);

      return Text(notifier.value.toString(), textDirection: TextDirection.ltr);
    }));

    expect(find.text('0'), findsOneWidget);

    notifier.value++;
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('HookElement exposes an immutable list of hooks', (tester) async {
    await tester.pumpWidget(HookBuilder(builder: (_) {
      Hook.use(HookTest<int>());
      Hook.use(HookTest<String>());
      return Container();
    }));

    final element = tester.element(find.byType(HookBuilder)) as HookElement;

    expect(element.debugHooks.length, 2);
    expect(element.debugHooks.first, isInstanceOf<HookStateTest<int>>());
    expect(element.debugHooks.last, isInstanceOf<HookStateTest<String>>());
    expect(() => element.debugHooks[0] = null, throwsUnsupportedError);
    expect(() => element.debugHooks.add(null), throwsUnsupportedError);
  });
  testWidgets(
      'until one build finishes without crashing, it is possible to add hooks',
      (tester) async {
    await tester.pumpWidget(HookBuilder(builder: (_) {
      throw 0;
    }));
    expect(tester.takeException(), 0);

    await tester.pumpWidget(HookBuilder(builder: (_) {
      Hook.use(HookTest<int>());
      throw 1;
    }));
    expect(tester.takeException(), 1);

    await tester.pumpWidget(HookBuilder(builder: (_) {
      Hook.use(HookTest<int>());
      Hook.use(HookTest<String>());
      throw 2;
    }));
    expect(tester.takeException(), 2);

    await tester.pumpWidget(HookBuilder(builder: (_) {
      Hook.use(HookTest<int>());
      Hook.use(HookTest<String>());
      Hook.use(HookTest<double>());
      return Container();
    }));
  });
  testWidgets(
      'until one build finishes without crashing, it is possible to add hooks #2',
      (tester) async {
    await tester.pumpWidget(HookBuilder(builder: (_) {
      throw 0;
    }));
    expect(tester.takeException(), 0);

    await tester.pumpWidget(HookBuilder(builder: (_) {
      Hook.use(HookTest<int>());
      throw 1;
    }));
    expect(tester.takeException(), 1);

    await tester.pumpWidget(HookBuilder(builder: (_) {
      Hook.use(HookTest<int>());
      Hook.use(HookTest<String>());
      Hook.use(HookTest<double>());
      throw 2;
    }));
    expect(tester.takeException(), 2);
  });

  testWidgets(
      'After a build suceeded, expections do not allow adding more hooks',
      (tester) async {
    await tester.pumpWidget(HookBuilder(builder: (_) {
      return Container();
    }));

    await tester.pumpWidget(HookBuilder(builder: (_) {
      throw 1;
    }));
    expect(tester.takeException(), 1);

    await tester.pumpWidget(HookBuilder(builder: (_) {
      Hook.use(HookTest<int>());
      return Container();
    }));
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets(
      "After hot-reload that throws it's still possible to add hooks until one build suceed",
      (tester) async {
    await tester.pumpWidget(HookBuilder(builder: (_) {
      return Container();
    }));

    hotReload(tester);

    await tester.pumpWidget(HookBuilder(builder: (_) {
      throw 0;
    }));
    expect(tester.takeException(), 0);

    await tester.pumpWidget(HookBuilder(builder: (_) {
      Hook.use(HookTest<int>());
      return Container();
    }));
  });

  testWidgets(
      'After hot-reload that throws, hooks are correctly disposed when build suceeeds with less hooks',
      (tester) async {
    await tester.pumpWidget(HookBuilder(builder: (_) {
      Hook.use(createHook());
      return Container();
    }));

    hotReload(tester);

    await tester.pumpWidget(HookBuilder(builder: (_) {
      throw 0;
    }));
    expect(tester.takeException(), 0);
    verifyNever(dispose());

    await tester.pumpWidget(HookBuilder(builder: (_) {
      return Container();
    }));

    verify(dispose()).called(1);
  });

  testWidgets('hooks can be disposed independently with keys', (tester) async {
    List<Object> keys;
    List<Object> keys2;

    final dispose2 = Func0<void>();
    when(builder.call(any)).thenAnswer((invocation) {
      Hook.use(HookTest<int>(dispose: dispose.call, keys: keys));
      Hook.use(HookTest<String>(dispose: dispose2.call, keys: keys2));
      return Container();
    });
    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyZeroInteractions(dispose);
    verifyZeroInteractions(dispose2);

    keys = [];
    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verify(dispose.call()).called(1);
    verifyZeroInteractions(dispose2);

    keys2 = [];
    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verify(dispose2.call()).called(1);
    verifyNoMoreInteractions(dispose);
  });
  testWidgets('keys recreate hookstate', (tester) async {
    List<Object> keys;

    final createState = Func0<HookStateTest<int>>();
    when(createState.call()).thenReturn(HookStateTest<int>());

    when(builder.call(any)).thenAnswer((invocation) {
      Hook.use(HookTest<int>(
        build: build.call,
        dispose: dispose.call,
        didUpdateHook: didUpdateHook.call,
        initHook: initHook.call,
        keys: keys,
        didBuild: didBuild,
        createStateFn: createState.call,
      ));
      return Container();
    });
    await tester.pumpWidget(HookBuilder(builder: builder.call));

    final context = find.byType(HookBuilder).evaluate().first;

    verifyInOrder([
      createState.call(),
      initHook.call(),
      build.call(context),
      didBuild.call(),
    ]);
    verifyNoMoreHookInteration();

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyInOrder([
      didUpdateHook.call(any),
      build.call(context),
      didBuild.call(),
    ]);
    verifyNoMoreHookInteration();

    // from null to array
    keys = [];
    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyInOrder([
      dispose.call(),
      createState.call(),
      initHook.call(),
      build.call(context),
      didBuild.call(),
    ]);
    verifyNoMoreHookInteration();

    // array immutable
    keys.add(42);

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyInOrder([
      didUpdateHook.call(any),
      build.call(context),
      didBuild.call(),
    ]);
    verifyNoMoreHookInteration();

    // new array but content equal
    keys = [42];

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyInOrder([
      didUpdateHook.call(any),
      build.call(context),
      didBuild.call(),
    ]);
    verifyNoMoreHookInteration();

    // new array new content
    keys = [44];

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyInOrder([
      dispose.call(),
      createState.call(),
      initHook.call(),
      build.call(context),
      didBuild.call()
    ]);
    verifyNoMoreHookInteration();
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

  testWidgets(
      'didBuild when build crash called after FlutterError.onError report',
      (tester) async {
    final onError = FlutterError.onError;
    FlutterError.onError = Func1<FlutterErrorDetails, void>();
    final errorBuilder = ErrorWidget.builder;
    ErrorWidget.builder = Func1<FlutterErrorDetails, Widget>();
    when(ErrorWidget.builder(any)).thenReturn(Container());
    try {
      when(build.call(any)).thenThrow(42);
      when(builder.call(any)).thenAnswer((invocation) {
        Hook.use(createHook());
        return Container();
      });

      await tester.pumpWidget(HookBuilder(
        builder: builder.call,
      ));
      tester.takeException();

      verifyInOrder([
        build.call(any),
        FlutterError.onError(any),
        ErrorWidget.builder(any),
        didBuild(),
      ]);
    } finally {
      FlutterError.onError = onError;
      ErrorWidget.builder = errorBuilder;
    }
  });

  testWidgets('didBuild called even if build crashed', (tester) async {
    when(build.call(any)).thenThrow(42);
    when(builder.call(any)).thenAnswer((invocation) {
      Hook.use(createHook());
      return Container();
    });

    await tester.pumpWidget(HookBuilder(
      builder: builder.call,
    ));
    expect(tester.takeException(), 42);

    verify(didBuild.call()).called(1);
  });
  testWidgets('all didBuild called even if one crashes', (tester) async {
    final didBuild2 = Func0<void>();

    when(didBuild.call()).thenThrow(42);
    when(builder.call(any)).thenAnswer((invocation) {
      Hook.use(createHook());
      Hook.use(HookTest<int>(didBuild: didBuild2));
      return Container();
    });

    await expectPump(
      () => tester.pumpWidget(HookBuilder(
        builder: builder.call,
      )),
      throwsA(42),
    );

    verifyInOrder([
      didBuild2.call(),
      didBuild.call(),
    ]);
  });

  testWidgets('calls didBuild before building children', (tester) async {
    final buildChild = Func1<BuildContext, Widget>();
    when(buildChild.call(any)).thenReturn(Container());

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        Hook.use(createHook());
        return Builder(builder: buildChild);
      },
    ));

    verifyInOrder([
      didBuild(),
      buildChild.call(any),
    ]);
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
      didBuild.call(),
    ]);
    verifyNoMoreHookInteration();

    when(build.call(context)).thenReturn(24);
    var previousHook = hook;

    await tester.pumpWidget(HookBuilder(
      builder: builder.call,
    ));

    expect(result, 24);
    verifyInOrder(
        [didUpdateHook.call(previousHook), build.call(any), didBuild.call()]);
    verifyNoMoreHookInteration();

    previousHook = hook;
    await tester.pump();

    verifyNoMoreHookInteration();

    await tester.pumpWidget(const SizedBox());

    verify(dispose.call()).called(1);
    verifyNoMoreHookInteration();
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

  testWidgets('hot-reload calls reassemble', (tester) async {
    final reassemble2 = Func0<void>();
    final didUpdateHook2 = Func1<void, Hook<void>>();
    await tester.pumpWidget(HookBuilder(builder: (context) {
      Hook.use(createHook());
      Hook.use(HookTest<void>(
          reassemble: reassemble2, didUpdateHook: didUpdateHook2));
      return Container();
    }));

    verifyNoMoreInteractions(reassemble);

    hotReload(tester);
    await tester.pump();

    verifyInOrder([
      reassemble.call(),
      reassemble2.call(),
      didUpdateHook.call(any),
      didUpdateHook2.call(any),
    ]);
    verifyNoMoreInteractions(reassemble);
  });

  testWidgets("hot-reload don't reassemble newly added hooks", (tester) async {
    await tester.pumpWidget(HookBuilder(builder: (context) {
      Hook.use(HookTest<int>());
      return Container();
    }));

    verifyNoMoreInteractions(reassemble);

    hotReload(tester);
    await tester.pumpWidget(HookBuilder(builder: (context) {
      Hook.use(HookTest<int>());
      Hook.use(createHook());
      return Container();
    }));

    verifyNoMoreInteractions(didUpdateHook);
    verifyNoMoreInteractions(reassemble);
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

    final context = find.byType(HookBuilder).evaluate().first;

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

    final context = find.byType(HookBuilder).evaluate().first;

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
    final context = find.byType(HookBuilder).evaluate().first;

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

    final context = find.byType(HookBuilder).evaluate().first;

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

    final context = find.byType(HookBuilder).evaluate().first;

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

class MyStatefulHook extends StatefulHookWidget {
  const MyStatefulHook({Key key, this.value, this.notifier}) : super(key: key);

  final int value;
  final ValueNotifier<int> notifier;

  @override
  _MyStatefulHookState createState() => _MyStatefulHookState();
}

class _MyStatefulHookState extends State<MyStatefulHook> {
  int value;

  @override
  void initState() {
    super.initState();
    // voluntarily ues widget.value to verify that state life-cycles are called
    value = widget.value;
  }

  @override
  void didUpdateWidget(MyStatefulHook oldWidget) {
    super.didUpdateWidget(oldWidget);
    value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '$value ${useValueListenable(widget.notifier)}',
      textDirection: TextDirection.ltr,
    );
  }
}
