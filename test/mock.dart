import 'package:flutter_hooks/hook.dart';
import 'package:mockito/mockito.dart';

export 'package:flutter_test/flutter_test.dart' hide Func0, Func1;

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
