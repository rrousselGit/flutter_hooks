import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/hook.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

export 'package:flutter_test/flutter_test.dart' hide Func0, Func1;
export 'package:mockito/mockito.dart';

class MockHook<R> extends Hook<R> {
  final MockHookState<R> state;

  MockHook([MockHookState<R> state]) : state = state ?? MockHookState();

  @override
  MockHookState<R> createState() => state;
}

class MockHookState<R> extends Mock implements HookState<R, MockHook<R>> {}

abstract class _Func0<R> {
  R call();
}

class Func0<R> extends Mock implements _Func0<R> {}

abstract class _Func1<T1, R> {
  R call(T1 value);
}

class Func1<T1, R> extends Mock implements _Func1<T1, R> {}

class HookTest<R> extends Hook<R> {
  final R Function(HookContext context) build;
  final void Function() dispose;
  final void Function() initHook;
  final void Function(HookTest<R> previousHook) didUpdateHook;

  HookTest({
    this.build,
    this.dispose,
    this.initHook,
    this.didUpdateHook,
  }) : super();

  @override
  HookStateTest<R> createState() => HookStateTest<R>();
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
    super.dispose();
    if (hook.dispose != null) {
      hook.dispose();
    }
  }

  @override
  void didUpdateHook(HookTest<R> oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.dispose != null) {
      hook.didUpdateHook(oldHook);
    }
  }

  @override
  R build(HookContext context) {
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

  TestWidgetsFlutterBinding.ensureInitialized().buildOwner..reassemble(root);
}
