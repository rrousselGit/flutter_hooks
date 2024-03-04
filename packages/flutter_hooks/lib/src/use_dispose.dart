part of 'hooks.dart';

/// Creates a general hook with customized `dispose` state.
T useDispose<T>(
  T Function() factory,
  void Function(T dispose) dispose, [
  String? label,
  List<Object?>? keys,
]) {
  return use(_DisposeHook(
    factory: factory,
    dispose: dispose,
    label: label,
    keys: keys,
  ));
}

class _DisposeHook<T> extends Hook<T> {
  const _DisposeHook({
    required this.factory,
    required this.dispose,
    this.label,
    List<Object?>? keys,
  }) : super(keys: keys);

  final T Function() factory;
  final void Function(T dispose) dispose;
  final String? label;

  @override
  HookState<T, Hook<T>> createState() {
    return _DisposeHookState(
      entity: factory(),
      disposeFunc: dispose,
      label: label,
    );
  }
}

class _DisposeHookState<T> extends HookState<T, _DisposeHook<T>> {
  _DisposeHookState({
    required this.entity,
    this.disposeFunc,
    this.label,
  });

  final String? label;
  final T entity;
  final void Function(T dispose)? disposeFunc;

  @override
  String get debugLabel => label ?? 'useDispose';

  @override
  T build(BuildContext context) => entity;

  @override
  void dispose() => disposeFunc?.call(entity);
}
