part of 'hook.dart';

class _MemoizedHook<T> extends Hook<T> {
  final T Function(T old) valueBuilder;
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

class _TickerProviderHook extends Hook<TickerProvider> {
  const _TickerProviderHook();

  @override
  _TickerProviderHookState createState() => _TickerProviderHookState();
}

class _TickerProviderHookState
    extends HookState<TickerProvider, _TickerProviderHook>
    implements TickerProvider {
  Ticker _ticker;

  @override
  Ticker createTicker(TickerCallback onTick) {
    assert(() {
      if (_ticker == null) return true;
      throw FlutterError(
          '${context.widget.runtimeType} attempted to use a useSingleTickerProvider multiple times.\n'
          'A SingleTickerProviderStateMixin can only be used as a TickerProvider once. If a '
          'TickerProvider is used for multiple AnimationController objects, or if it is passed to other '
          'objects and those objects might use it more than one time in total, then instead of '
          'using useSingleTickerProvider, use a regular useTickerProvider.');
    }());
    _ticker = Ticker(onTick, debugLabel: 'created by $context');
    return _ticker;
  }

  @override
  void dispose() {
    assert(() {
      if (_ticker == null || !_ticker.isActive) return true;
      throw FlutterError(
          'useSingleTickerProvider created a Ticker, but at the time '
          'dispose() was called on the Hook, that Ticker was still active. Tickers used '
          ' by AnimationControllers should be disposed by calling dispose() on '
          ' the AnimationController itself. Otherwise, the ticker will leak.\n');
    }());
    super.dispose();
  }

  @override
  TickerProvider build(HookContext context) {
    if (_ticker != null) _ticker.muted = !TickerMode.of(context);
    return this;
  }
}

class _AnimationControllerHook extends Hook<AnimationController> {
  final Duration duration;
  final String debugLabel;
  final double initialValue;
  final double lowerBound;
  final double upperBound;
  final TickerProvider vsync;
  final AnimationBehavior animationBehavior;

  const _AnimationControllerHook({
    this.duration,
    this.debugLabel,
    this.initialValue,
    this.lowerBound,
    this.upperBound,
    this.vsync,
    this.animationBehavior,
  });

  @override
  _AnimationControllerHookState createState() =>
      _AnimationControllerHookState();
}

class _AnimationControllerHookState
    extends HookState<AnimationController, _AnimationControllerHook> {
  AnimationController _animationController;

  @override
  AnimationController build(HookContext context) {
    final vsync = hook.vsync ?? context.useSingleTickerProvider();

    _animationController ??= AnimationController(
      vsync: vsync,
      duration: hook.duration,
      debugLabel: hook.debugLabel,
      lowerBound: hook.lowerBound,
      upperBound: hook.upperBound,
      animationBehavior: hook.animationBehavior,
      value: hook.initialValue,
    );

    context
      ..useValueChanged(hook.vsync, resync)
      ..useValueChanged(hook.duration, duration);
    return _animationController;
  }

  void resync(_, __) {
    _animationController.resync(hook.vsync);
  }

  void duration(_, __) {
    _animationController.duration = hook.duration;
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
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
