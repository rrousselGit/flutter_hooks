// ignore_for_file: one_member_abstracts

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

export 'package:flutter_test/flutter_test.dart'
    hide Func0, Func1, Func2, Func3, Func4, Func5, Func6;
export 'package:mockito/mockito.dart';

abstract class _Func0<R> {
  R call();
}

class Func0<R> extends Mock implements _Func0<R> {}

abstract class _Func1<T1, R> {
  R call(T1 value);
}

class Func1<T1, R> extends Mock implements _Func1<T1, R> {}

abstract class _Func2<T1, T2, R> {
  R call(T1 value, T2 value2);
}

class Func2<T1, T2, R> extends Mock implements _Func2<T1, T2, R> {}

class HookTest<R> extends Hook<R> {
  // ignore: prefer_const_constructors_in_immutables
  HookTest({
    this.build,
    this.dispose,
    this.initHook,
    this.didUpdateHook,
    this.reassemble,
    this.createStateFn,
    this.didBuild,
    this.deactivate,
    List<Object> keys,
  }) : super(keys: keys);

  final R Function(BuildContext context) build;
  final void Function() dispose;
  final void Function() didBuild;
  final void Function() initHook;
  final void Function() deactivate;
  final void Function(HookTest<R> previousHook) didUpdateHook;
  final void Function() reassemble;
  final HookStateTest<R> Function() createStateFn;

  @override
  HookStateTest<R> createState() =>
      createStateFn != null ? createStateFn() : HookStateTest<R>();
}

class HookStateTest<R> extends HookState<R, HookTest<R>> {
  @override
  void initHook() {
    super.initHook();
    if (hook.initHook != null) {
      hook.initHook();
    }
  }

  @override
  void dispose() {
    if (hook.dispose != null) {
      hook.dispose();
    }
  }

  @override
  void didUpdateHook(HookTest<R> oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.didUpdateHook != null) {
      hook.didUpdateHook(oldHook);
    }
  }

  @override
  void didBuild() {
    super.didBuild();
    if (hook.didBuild != null) {
      hook.didBuild();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    if (hook.reassemble != null) {
      hook.reassemble();
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    if (hook.deactivate != null) {
      hook.deactivate();
    }
  }

  @override
  R build(BuildContext context) {
    if (hook.build != null) {
      return hook.build(context);
    }
    return null;
  }
}

Element _rootOf(Element element) {
  Element root;
  element.visitAncestorElements((e) {
    if (e != null) {
      root = e;
    }
    return e != null;
  });
  return root;
}

void hotReload(WidgetTester tester) {
  final root = _rootOf(tester.allElements.first);

  TestWidgetsFlutterBinding.ensureInitialized().buildOwner.reassemble(root);
}

Future<void> expectPump(
  Future Function() pump,
  dynamic matcher, {
  String reason,
  dynamic skip,
}) async {
  FlutterErrorDetails details;
  if (skip == null || skip != false) {
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (d) {
      details = d;
    };
    await pump();
    FlutterError.onError = previousErrorHandler;
  }

  await expectLater(
    details != null
        ? Future<void>.error(details.exception, details.stack)
        : Future<void>.value(),
    matcher,
    reason: reason,
    skip: skip,
  );
}
