part of 'hooks.dart';

T _useChangeNotifier<T extends ChangeNotifier>(
  ValueGetter<T> builder,
  List<Object?>? keys,
) {
  return use(_ChangeNotifierHook(builder, keys));
}

class _ChangeNotifierHook<T extends ChangeNotifier> extends Hook<T> {
  const _ChangeNotifierHook(
    this.builder,
    List<Object?>? keys,
  ) : super(keys: keys);

  final ValueGetter<T> builder;

  @override
  HookState<T, Hook<T>> createState() => _ChangeNotifierHookState<T>(builder);
}

class _ChangeNotifierHookState<T extends ChangeNotifier>
    extends HookState<T, _ChangeNotifierHook<T>> {
  _ChangeNotifierHookState(ValueGetter<T> builder) : controller = builder();

  final T controller;

  @override
  String get debugLabel => 'use${controller.runtimeType}';

  @override
  T build(BuildContext context) => controller;

  @override
  void dispose() => controller.dispose();
}
