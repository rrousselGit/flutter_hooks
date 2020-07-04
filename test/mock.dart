// ignore_for_file: one_member_abstracts

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

export 'package:flutter_test/flutter_test.dart'
    hide Func0, Func1, Func2, Func3, Func4, Func5, Func6;
export 'package:mockito/mockito.dart';

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

class MockSetState extends Mock {
  void call();
}

class MockInitHook extends Mock {
  void call();
}

class MockCreateState<T extends HookState<dynamic, Hook>> extends Mock {
  T call();
}

class MockBuild<T> extends Mock {
  T call(BuildContext context);
}

class MockDeactivate extends Mock {
  void call();
}

class MockErrorBuilder extends Mock {
  Widget call(FlutterErrorDetails error);
}

class MockOnError extends Mock {
  void call(FlutterErrorDetails error);
}

class MockReassemble extends Mock {
  void call();
}

class MockDidUpdateHook extends Mock {
  void call(HookTest hook);
}

class MockDispose extends Mock {
  void call();
}
