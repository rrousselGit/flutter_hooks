part of 'hooks.dart';

/// Subscribes to an [Animation] and return its value.
///
/// See also:
///   * [Animation]
///   * [useValueListenable], [useListenable], [useStream]
T useAnimation<T>(Animation<T> animation) {
  useListenable(animation);
  return animation.value;
}

/// Creates an [AnimationController] automatically disposed.
///
/// If no [vsync] is provided, the [TickerProvider] is implicitly obtained using [useSingleTickerProvider].
/// If a [vsync] is specified, changing the instance of [vsync] will result in a call to [AnimationController.resync].
/// It is not possible to switch between implicit and explicit [vsync].
///
/// Changing the [duration] parameter automatically updates [AnimationController.duration].
///
/// [initialValue], [lowerBound], [upperBound] and [debugLabel] are ignored after the first call.
///
/// See also:
///   * [AnimationController]
///   * [useAnimation]
AnimationController useAnimationController({
  Duration duration,
  String debugLabel,
  double initialValue = 0,
  double lowerBound = 0,
  double upperBound = 1,
  TickerProvider vsync,
  AnimationBehavior animationBehavior = AnimationBehavior.normal,
  List keys,
}) {
  return Hook.use(_AnimationControllerHook(
    duration: duration,
    debugLabel: debugLabel,
    initialValue: initialValue,
    lowerBound: lowerBound,
    upperBound: upperBound,
    vsync: vsync,
    animationBehavior: animationBehavior,
    keys: keys,
  ));
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
    List keys,
  }) : super(keys: keys);

  @override
  _AnimationControllerHookState createState() =>
      _AnimationControllerHookState();
}

class _AnimationControllerHookState
    extends HookState<AnimationController, _AnimationControllerHook> {
  AnimationController _animationController;

  @override
  void didUpdateHook(_AnimationControllerHook oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.vsync != oldHook.vsync) {
      assert(hook.vsync != null && oldHook.vsync != null, '''
Switching between controller and uncontrolled vsync is not allowed.
''');
      _animationController.resync(hook.vsync);
    }

    if (hook.duration != oldHook.duration) {
      _animationController.duration = hook.duration;
    }
  }

  @override
  AnimationController build(BuildContext context) {
    final vsync = hook.vsync ?? useSingleTickerProvider(keys: hook.keys);

    _animationController ??= AnimationController(
      vsync: vsync,
      duration: hook.duration,
      debugLabel: hook.debugLabel,
      lowerBound: hook.lowerBound,
      upperBound: hook.upperBound,
      animationBehavior: hook.animationBehavior,
      value: hook.initialValue,
    );

    return _animationController;
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
  }
}

/// Creates a single usage [TickerProvider].
///
/// See also:
///  * [SingleTickerProviderStateMixin]
TickerProvider useSingleTickerProvider({List keys}) {
  return Hook.use(
    keys != null
        ? _SingleTickerProviderHook(keys)
        : const _SingleTickerProviderHook(),
  );
}

class _SingleTickerProviderHook extends Hook<TickerProvider> {
  const _SingleTickerProviderHook([List keys]) : super(keys: keys);

  @override
  _TickerProviderHookState createState() => _TickerProviderHookState();
}

class _TickerProviderHookState
    extends HookState<TickerProvider, _SingleTickerProviderHook>
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
  TickerProvider build(BuildContext context) {
    if (_ticker != null) _ticker.muted = !TickerMode.of(context);
    return this;
  }
}
