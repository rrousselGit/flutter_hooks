part of 'hooks.dart';

/// Cache the instance of a complex object.
///
/// [useMemoized] will immediatly call [valueBuilder] on first call and store its result.
/// Later, when [HookWidget] rebuilds, the call to [useMemoized] will return the previously created instance without calling [valueBuilder].
///
/// A later call of [useMemoized] with different [keys] will call [useMemoized] again to create a new instance.
T useMemoized<T>(T Function() valueBuilder,
    [List<Object> keys = const <dynamic>[]]) {
  return use(_MemoizedHook(
    valueBuilder,
    keys: keys,
  ));
}

class _MemoizedHook<T> extends Hook<T> {
  const _MemoizedHook(
    this.valueBuilder, {
    List<Object> keys = const <dynamic>[],
  })  : assert(valueBuilder != null, 'valueBuilder cannot be null'),
        assert(keys != null, 'keys cannot be null'),
        super(keys: keys);

  final T Function() valueBuilder;

  @override
  _MemoizedHookState<T> createState() => _MemoizedHookState<T>();
}

class _MemoizedHookState<T> extends HookState<T, _MemoizedHook<T>> {
  T value;

  @override
  void initHook() {
    super.initHook();
    value = hook.valueBuilder();
  }

  @override
  T build(BuildContext context) {
    return value;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<T>('useMemoized<$T>', value));
  }
}

/// Watches a value and calls a callback whenever the value changed.
///
/// [useValueChanged] takes a [valueChange] callback and calls it whenever [value] changed.
/// [valueChange] will _not_ be called on the first [useValueChanged] call.
///
/// [useValueChanged] can also be used to interpolate
/// Whenever [useValueChanged] is called with a diffent [value], calls [valueChange].
/// The value returned by [useValueChanged] is the latest returned value of [valueChange] or `null`.
///
/// The following example calls [AnimationController.forward] whenever `color` changes
///
/// ```dart
/// AnimationController controller;
/// Color color;
///
/// useValueChanged(color, (_, __)) {
///     controller.forward();
/// });
/// ```
R useValueChanged<T, R>(
  T value,
  R Function(T oldValue, R oldResult) valueChange,
) {
  return use(_ValueChangedHook(value, valueChange));
}

class _ValueChangedHook<T, R> extends Hook<R> {
  const _ValueChangedHook(this.value, this.valueChanged)
      : assert(valueChanged != null, 'valueChanged cannot be null');

  final R Function(T oldValue, R oldResult) valueChanged;
  final T value;

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
  R build(BuildContext context) {
    return _result;
  }
}

typedef Dispose = void Function();

/// Useful for side-effects and optionally canceling them.
///
/// [useEffect] is called synchronously on every `build`, unless
/// [keys] is specified. In which case [useEffect] is called again only if
/// any value inside [keys] as changed.
///
/// It takes an [effect] callback and calls it synchronously.
/// That [effect] may optionally return a function, which will be called when the [effect] is called again or if the widget is disposed.
///
/// By default [effect] is called on every `build` call, unless [keys] is specified.
/// In which case, [effect] is called once on the first [useEffect] call and whenever something within [keys] change/
///
/// The following example call [useEffect] to subscribes to a [Stream] and cancel the subscription when the widget is disposed.
/// ALso ifthe [Stream] change, it will cancel the listening on the previous [Stream] and listen to the new one.
///
/// ```dart
/// Stream stream;
/// useEffect(() {
///     final subscription = stream.listen(print);
///     // This will cancel the subscription when the widget is disposed
///     // or if the callback is called again.
///     return subscription.cancel;
///   },
///   // when the stream change, useEffect will call the callback again.
///   [stream],
/// );
/// ```
void useEffect(Dispose Function() effect, [List<Object> keys]) {
  use(_EffectHook(effect, keys));
}

class _EffectHook extends Hook<void> {
  const _EffectHook(this.effect, [List<Object> keys])
      : assert(effect != null, 'effect cannot be null'),
        super(keys: keys);

  final Dispose Function() effect;

  @override
  _EffectHookState createState() => _EffectHookState();
}

class _EffectHookState extends HookState<void, _EffectHook> {
  Dispose disposer;

  @override
  void initHook() {
    super.initHook();
    scheduleEffect();
  }

  @override
  void didUpdateHook(_EffectHook oldHook) {
    super.didUpdateHook(oldHook);

    if (hook.keys == null) {
      if (disposer != null) {
        disposer();
      }
      scheduleEffect();
    }
  }

  @override
  void build(BuildContext context) {}

  @override
  void dispose() {
    if (disposer != null) {
      disposer();
    }
  }

  void scheduleEffect() {
    disposer = hook.effect();
  }
}

/// Create variable and subscribes to it.
///
/// Whenever [ValueNotifier.value] updates, it will mark the caller [HookWidget]
/// as needing build.
/// On first call, inits [ValueNotifier] to [initialData]. [initialData] is ignored
/// on subsequent calls.
///
/// The following example showcase a basic counter application.
///
/// ```dart
/// class Counter extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final counter = useState(0);
///
///     return GestureDetector(
///       // automatically triggers a rebuild of Counter widget
///       onTap: () => counter.value++,
///       child: Text(counter.value.toString()),
///     );
///   }
/// }
/// ```
///
/// See also:
///
///  * [ValueNotifier]
///  * [useStreamController], an alternative to [ValueNotifier] for state.
ValueNotifier<T> useState<T>([T initialData]) {
  return use(_StateHook(initialData: initialData));
}

class _StateHook<T> extends Hook<ValueNotifier<T>> {
  const _StateHook({this.initialData});

  final T initialData;

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
  }

  @override
  ValueNotifier<T> build(BuildContext context) {
    return _state;
  }

  void _listener() {
    setState(() {});
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<T>('useState<$T>', _state.value));
  }
}
