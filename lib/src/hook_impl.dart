part of 'hook.dart';

class _MemoizedHook<T> extends Hook<T> {
  final T Function(T oldValue) valueBuilder;
  final List parameters;

  const _MemoizedHook(this.valueBuilder, {this.parameters = const []})
      : assert(valueBuilder != null),
        assert(parameters != null);

  @override
  _MemoizedHookState<T> createState() => _MemoizedHookState<T>();
}

class _MemoizedHookState<T> extends HookState<T, _MemoizedHook<T>> {
  T value;

  @override
  void initHook() {
    super.initHook();
    value = hook.valueBuilder(null);
  }

  @override
  void didUpdateHook(_MemoizedHook<T> oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.parameters != oldHook.parameters &&
        (hook.parameters.length != oldHook.parameters.length ||
            _hasDiffWith(oldHook.parameters))) {
      value = hook.valueBuilder(value);
    }
  }

  bool _hasDiffWith(List parameters) {
    for (var i = 0; i < parameters.length; i++) {
      if (parameters[i] != hook.parameters[i]) {
        return true;
      }
    }
    return false;
  }

  @override
  T build(HookContext context) {
    return value;
  }
}

class _ValueChangedHook<T, R> extends Hook<R> {
  final R Function(T oldValue, R oldResult) valueChanged;
  final T value;

  const _ValueChangedHook(this.value, this.valueChanged)
      : assert(valueChanged != null);

  @override
  _ValueChangedHookState<T, R> createState() => _ValueChangedHookState<T, R>();
}

class _ValueChangedHookState<T, R>
    extends HookState<R, _ValueChangedHook<T, R>> {
  R _result;

  @override
  void didUpdateHook(_ValueChangedHook<T, R> oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.value != oldHook.value) {
      _result = hook.valueChanged(oldHook.value, _result);
    }
  }

  @override
  R build(HookContext context) {
    return _result;
  }
}

class _StateHook<T> extends Hook<ValueNotifier<T>> {
  final T initialData;

  const _StateHook({this.initialData});

  @override
  _StateHookState<T> createState() => _StateHookState();
}

class _StateHookState<T> extends HookState<ValueNotifier<T>, _StateHook<T>> {
  ValueNotifier<T> _state;

  @override
  void initHook() {
    super.initHook();
    _state = ValueNotifier(hook.initialData)..addListener(_listener);
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  ValueNotifier<T> build(HookContext context) {
    return _state;
  }

  void _listener() {
    setState(() {});
  }
}

/// A [HookWidget] that defer its [HookWidget.build] to a callback
class HookBuilder extends HookWidget {
  /// The callback used by [HookBuilder] to create a widget.
  ///
  /// If the passed [HookContext] trigger a rebuild, [builder] will be called again.
  /// [builder] must not return `null`.
  final Widget Function(HookContext context) builder;

  /// Creates a widget that delegates its build to a callback.
  ///
  /// The [builder] argument must not be null.
  const HookBuilder({
    @required this.builder,
    Key key,
  })  : assert(builder != null),
        super(key: key);

  @override
  Widget build(HookContext context) => builder(context);
}
