part of 'framework.dart';

/// A [HookWidget] that defer its [HookWidget.build] to a callback
class HookBuilder extends HookWidget {
  /// The callback used by [HookBuilder] to create a widget.
  ///
  /// If a [Hook] asks for a rebuild, [builder] will be called again.
  /// [builder] must not return `null`.
  final Widget Function(BuildContext context) builder;

  /// Creates a widget that delegates its build to a callback.
  ///
  /// The [builder] argument must not be null.
  const HookBuilder({
    @required this.builder,
    Key key,
  })  : assert(builder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) => builder(context);
}

/// A state holder that allows mutations by dispatching actions.
abstract class Store<State, Action> {
  /// The current state.
  ///
  /// This value may change after a call to [dispatch].
  State get state;

  /// Dispatches an action.
  ///
  /// Actions are dispatched synchronously.
  /// It is impossible to try to dispatch actions during [HookWidget.build].
  void dispatch(Action action);
}

/// Composes an [Action] and a [State] to create a new [State].
///
/// [Reducer] must never return `null`, even if [state] or [action] are `null`.
typedef Reducer<State, Action> = State Function(State state, Action action);

/// An alternative to [useState] for more complex states.
///
/// [useReducer] manages an read only state that can be updated
/// by dispatching actions which are interpreted by a [Reducer].
///
/// [reducer] is immediatly called on first build with [initialAction]
/// and [initialState] as parameter.
///
/// It is possible to change the [reducer] by calling [useReducer]
///  with a new [Reducer].
///
/// See also:
///  * [Reducer]
///  * [Store]
Store<State, Action> useReducer<State extends Object, Action>(
  Reducer<State, Action> reducer, {
  State initialState,
  Action initialAction,
}) {
  return Hook.use(_ReducerdHook(reducer,
      initialAction: initialAction, initialState: initialState));
}

class _ReducerdHook<State, Action> extends Hook<Store<State, Action>> {
  final Reducer<State, Action> reducer;
  final State initialState;
  final Action initialAction;

  const _ReducerdHook(this.reducer, {this.initialState, this.initialAction})
      : assert(reducer != null);

  @override
  _ReducerdHookState<State, Action> createState() =>
      _ReducerdHookState<State, Action>();
}

class _ReducerdHookState<State, Action>
    extends HookState<Store<State, Action>, _ReducerdHook<State, Action>>
    implements Store<State, Action> {
  @override
  State state;

  @override
  void initHook() {
    super.initHook();
    state = hook.reducer(hook.initialState, hook.initialAction);
    assert(state != null);
  }

  @override
  void dispatch(Action action) {
    final res = hook.reducer(state, action);
    assert(res != null);
    if (state != res) {
      setState(() {
        state = res;
      });
    }
  }

  @override
  Store<State, Action> build(BuildContext context) {
    return this;
  }
}

/// Create and cache the instance of an object.
///
/// [useMemoized] will immediatly call [valueBuilder] on first call and store its result.
/// Later calls to [useMemoized] will reuse the created instance.
///
///  * [keys] can be use to specify a list of objects for [useMemoized] to watch.
/// So that whenever [Object.operator==] fails on any parameter or if the length of [keys] changes,
/// [valueBuilder] is called again.
T useMemoized<T>(T Function() valueBuilder, [List keys = const <dynamic>[]]) {
  return Hook.use(_MemoizedHook(
    valueBuilder,
    keys: keys,
  ));
}

/// Obtain the [BuildContext] of the currently builder [HookWidget].
BuildContext useContext() {
  assert(HookElement._currentContext != null,
      '`useContext` can only be called from the build method of HookWidget');
  return HookElement._currentContext;
}

class _MemoizedHook<T> extends Hook<T> {
  final T Function() valueBuilder;

  const _MemoizedHook(this.valueBuilder, {List keys = const <dynamic>[]})
      : assert(valueBuilder != null),
        assert(keys != null),
        super(keys: keys);

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
}

/// Watches a value.
///
/// Whenever [useValueChanged] is called with a diffent [value], calls [valueChange].
/// The value returned by [useValueChanged] is the latest returned value of [valueChange] or `null`.
R useValueChanged<T, R>(T value, R valueChange(T oldValue, R oldResult)) {
  return Hook.use(_ValueChangedHook(value, valueChange));
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
  R build(BuildContext context) {
    return _result;
  }
}

/// Create  value and subscribes to it.
///
/// Whenever [ValueNotifier.value] updates, it will mark the caller [HookWidget]
/// as needing build.
/// On first call, inits [ValueNotifier] to [initialData]. [initialData] is ignored
/// on subsequent calls.
///
/// See also:
///
///  * [ValueNotifier]
///  * [useStreamController], an alternative to [ValueNotifier] for state.
ValueNotifier<T> useState<T>([T initialData]) {
  return Hook.use(_StateHook(initialData: initialData));
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
  ValueNotifier<T> build(BuildContext context) {
    return _state;
  }

  void _listener() {
    setState(() {});
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

/// Subscribes to a [ValueListenable] and return its value.
///
/// See also:
///   * [ValueListenable]
///   * [useListenable], [useAnimation], [useStream]
T useValueListenable<T>(ValueListenable<T> valueListenable) {
  useListenable(valueListenable);
  return valueListenable.value;
}

/// Subscribes to a [Listenable] and mark the widget as needing build
/// whenever the listener is called.
///
/// See also:
///   * [Listenable]
///   * [useValueListenable], [useAnimation], [useStream]
void useListenable(Listenable listenable) {
  Hook.use(_ListenableHook(listenable));
}

/// Subscribes to an [Animation] and return its value.
///
/// See also:
///   * [Animation]
///   * [useValueListenable], [useListenable], [useStream]
T useAnimation<T>(Animation<T> animation) {
  useListenable(animation);
  return animation.value;
}

class _ListenableHook extends Hook<void> {
  final Listenable listenable;

  const _ListenableHook(this.listenable) : assert(listenable != null);

  @override
  _ListenableStateHook createState() => _ListenableStateHook();
}

class _ListenableStateHook extends HookState<void, _ListenableHook> {
  @override
  void initHook() {
    super.initHook();
    hook.listenable.addListener(_listener);
  }

  @override
  void didUpdateHook(_ListenableHook oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.listenable != oldHook.listenable) {
      oldHook.listenable.removeListener(_listener);
      hook.listenable.addListener(_listener);
    }
  }

  @override
  void build(BuildContext context) {}

  void _listener() {
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    hook.listenable.removeListener(_listener);
  }
}

/// Subscribes to a [Future] and return its current state in an [AsyncSnapshot].
///
/// * [preserveState] defines if the current value should be preserved when changing
/// the [Future] instance.
///
/// See also:
///   * [Future]
///   * [useValueListenable], [useListenable], [useAnimation]
AsyncSnapshot<T> useFuture<T>(Future<T> future,
    {T initialData, bool preserveState = true}) {
  return Hook.use(_FutureHook(future,
      initialData: initialData, preserveState: preserveState));
}

class _FutureHook<T> extends Hook<AsyncSnapshot<T>> {
  final Future<T> future;
  final bool preserveState;
  final T initialData;

  const _FutureHook(this.future, {this.initialData, this.preserveState = true});

  @override
  _FutureStateHook<T> createState() => _FutureStateHook<T>();
}

class _FutureStateHook<T> extends HookState<AsyncSnapshot<T>, _FutureHook<T>> {
  /// An object that identifies the currently active callbacks. Used to avoid
  /// calling setState from stale callbacks, e.g. after disposal of this state,
  /// or after widget reconfiguration to a new Future.
  Object _activeCallbackIdentity;
  AsyncSnapshot<T> _snapshot;

  @override
  void initHook() {
    super.initHook();
    _snapshot =
        AsyncSnapshot<T>.withData(ConnectionState.none, hook.initialData);
    _subscribe();
  }

  @override
  void didUpdateHook(_FutureHook<T> oldHook) {
    super.didUpdateHook(oldHook);
    if (oldHook.future != hook.future) {
      if (_activeCallbackIdentity != null) {
        _unsubscribe();
        if (hook.preserveState) {
          _snapshot = _snapshot.inState(ConnectionState.none);
        } else {
          _snapshot =
              AsyncSnapshot<T>.withData(ConnectionState.none, hook.initialData);
        }
      }
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    if (hook.future != null) {
      final callbackIdentity = Object();
      _activeCallbackIdentity = callbackIdentity;
      hook.future.then<void>((T data) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withData(ConnectionState.done, data);
          });
        }
      }, onError: (Object error) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withError(ConnectionState.done, error);
          });
        }
      });
      _snapshot = _snapshot.inState(ConnectionState.waiting);
    }
  }

  void _unsubscribe() {
    _activeCallbackIdentity = null;
  }

  @override
  AsyncSnapshot<T> build(BuildContext context) {
    return _snapshot;
  }
}

/// Subscribes to a [Stream] and return its current state in an [AsyncSnapshot].
///
/// See also:
///   * [Stream]
///   * [useValueListenable], [useListenable], [useAnimation]
AsyncSnapshot<T> useStream<T>(Stream<T> stream,
    {T initialData, bool preserveState = true}) {
  return Hook.use(_StreamHook(
    stream,
    initialData: initialData,
    preserveState: preserveState,
  ));
}

class _StreamHook<T> extends Hook<AsyncSnapshot<T>> {
  final Stream<T> stream;
  final T initialData;
  final bool preserveState;

  _StreamHook(this.stream, {this.initialData, this.preserveState = true});

  @override
  _StreamHookState<T> createState() => _StreamHookState<T>();
}

/// a clone of [StreamBuilderBase] implementation
class _StreamHookState<T> extends HookState<AsyncSnapshot<T>, _StreamHook<T>> {
  StreamSubscription<T> _subscription;
  AsyncSnapshot<T> _summary;

  @override
  void initHook() {
    super.initHook();
    _summary = initial();
    _subscribe();
  }

  @override
  void didUpdateHook(_StreamHook<T> oldWidget) {
    super.didUpdateHook(oldWidget);
    if (oldWidget.stream != hook.stream) {
      if (_subscription != null) {
        _unsubscribe();
        if (hook.preserveState) {
          _summary = afterDisconnected(_summary);
        } else {
          _summary = initial();
        }
      }
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    if (hook.stream != null) {
      _subscription = hook.stream.listen((T data) {
        setState(() {
          _summary = afterData(_summary, data);
        });
      }, onError: (Object error) {
        setState(() {
          _summary = afterError(_summary, error);
        });
      }, onDone: () {
        setState(() {
          _summary = afterDone(_summary);
        });
      });
      _summary = afterConnected(_summary);
    }
  }

  void _unsubscribe() {
    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }
  }

  @override
  AsyncSnapshot<T> build(BuildContext context) {
    return _summary;
  }

  AsyncSnapshot<T> initial() =>
      AsyncSnapshot<T>.withData(ConnectionState.none, hook.initialData);

  AsyncSnapshot<T> afterConnected(AsyncSnapshot<T> current) =>
      current.inState(ConnectionState.waiting);

  AsyncSnapshot<T> afterData(AsyncSnapshot<T> current, T data) {
    return AsyncSnapshot<T>.withData(ConnectionState.active, data);
  }

  AsyncSnapshot<T> afterError(AsyncSnapshot<T> current, Object error) {
    return AsyncSnapshot<T>.withError(ConnectionState.active, error);
  }

  AsyncSnapshot<T> afterDone(AsyncSnapshot<T> current) =>
      current.inState(ConnectionState.done);

  AsyncSnapshot<T> afterDisconnected(AsyncSnapshot<T> current) =>
      current.inState(ConnectionState.none);
}

typedef Dispose = void Function();

/// A hook for side-effects
///
/// [useEffect] is called synchronously on every [HookWidget.build], unless
/// [keys] is specified. In which case [useEffect] is called again only if
/// any value inside [keys] as changed.
void useEffect(Dispose Function() effect, [List keys]) {
  Hook.use(_EffectHook(effect, keys));
}

class _EffectHook extends Hook<void> {
  final Dispose Function() effect;

  const _EffectHook(this.effect, [List keys])
      : assert(effect != null),
        super(keys: keys);

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
    super.dispose();
  }

  void scheduleEffect() {
    disposer = hook.effect();
  }
}

/// Creates a [StreamController] automatically disposed.
///
/// See also:
///   * [StreamController]
///   * [useStream]
StreamController<T> useStreamController<T>(
    {bool sync = false,
    VoidCallback onListen,
    VoidCallback onCancel,
    List keys}) {
  return Hook.use(_StreamControllerHook(
    onCancel: onCancel,
    onListen: onListen,
    sync: sync,
    keys: keys,
  ));
}

class _StreamControllerHook<T> extends Hook<StreamController<T>> {
  final bool sync;
  final VoidCallback onListen;
  final VoidCallback onCancel;

  const _StreamControllerHook(
      {this.sync = false, this.onListen, this.onCancel, List keys})
      : super(keys: keys);

  @override
  _StreamControllerHookState<T> createState() =>
      _StreamControllerHookState<T>();
}

class _StreamControllerHookState<T>
    extends HookState<StreamController<T>, _StreamControllerHook<T>> {
  StreamController<T> _controller;

  @override
  void initHook() {
    super.initHook();
    _controller = StreamController.broadcast(
      sync: hook.sync,
      onCancel: hook.onCancel,
      onListen: hook.onListen,
    );
  }

  @override
  void didUpdateHook(_StreamControllerHook<T> oldHook) {
    super.didUpdateHook(oldHook);
    if (oldHook.onListen != hook.onListen) {
      _controller.onListen = hook.onListen;
    }
    if (oldHook.onCancel != hook.onCancel) {
      _controller.onCancel = hook.onCancel;
    }
  }

  @override
  StreamController<T> build(BuildContext context) {
    return _controller;
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}

/// Creates a [ValueNotifier] automatically disposed.
///
/// As opposed to `useState`, this hook do not subscribes to [ValueNotifier].
/// This allows a more granular rebuild.
///
/// See also:
///   * [ValueNotifier]
///   * [useValueListenable]
ValueNotifier<T> useValueNotifier<T>([T intialData, List keys]) {
  return Hook.use(_ValueNotifierHook(
    initialData: intialData,
    keys: keys,
  ));
}

class _ValueNotifierHook<T> extends Hook<ValueNotifier<T>> {
  final T initialData;

  const _ValueNotifierHook({List keys, this.initialData}) : super(keys: keys);

  @override
  _UseValueNotiferHookState<T> createState() => _UseValueNotiferHookState<T>();
}

class _UseValueNotiferHookState<T>
    extends HookState<ValueNotifier<T>, _ValueNotifierHook<T>> {
  ValueNotifier<T> notifier;

  @override
  void initHook() {
    super.initHook();
    notifier = ValueNotifier(hook.initialData);
  }

  @override
  ValueNotifier<T> build(BuildContext context) {
    return notifier;
  }

  @override
  void dispose() {
    notifier.dispose();
    super.dispose();
  }
}

/// Creates a [ScrollController] automatically disposed.
///
/// See also:
///   * [ScrollController]
final useScrollController = UseScrollController();

/// Using various [ScrollController]s.
///
/// See also:
///   * [call]
///   * [tracking]
class UseScrollController {
  /// Creates an [ScrollController] automatically disposed.
  ///
  /// [initialScrollOffset], [keepScrollOffset] and [debugLabel] are ignored after the first call.
  ///
  /// See also:
  ///   * [ScrollController]
  ScrollController call({
    String debugLabel,
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    List keys,
  }) {
    return Hook.use(_ScrollControllerHook(
      debugLabel: debugLabel,
      initialScrollOffset: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      keys: keys,
    ));
  }

  /// Creates an [TrackingScrollController] automatically disposed.
  ///
  /// [initialScrollOffset], [keepScrollOffset] and [debugLabel] are ignored after the first call.
  ///
  /// See also:
  ///   * [TrackingScrollController]
  TrackingScrollController tracking({
    String debugLabel,
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    List keys,
  }) {
    return Hook.use(_TrackingScrollControllerHook(
      debugLabel: debugLabel,
      initialScrollOffset: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      keys: keys,
    ));
  }
}

class _ScrollControllerHook extends Hook<ScrollController> {
  final String debugLabel;
  final double initialScrollOffset;
  final bool keepScrollOffset;

  const _ScrollControllerHook({
    this.debugLabel,
    this.initialScrollOffset,
    this.keepScrollOffset,
    List keys,
  }) : super(keys: keys);

  @override
  _ScrollControllerHookState createState() => _ScrollControllerHookState();
}

class _ScrollControllerHookState
    extends HookState<ScrollController, _ScrollControllerHook> {
  ScrollController _scrollController;

  @override
  void initHook() {
    _scrollController = ScrollController(
      initialScrollOffset: hook.initialScrollOffset,
      keepScrollOffset: hook.keepScrollOffset,
      debugLabel: hook.debugLabel,
    );
  }

  @override
  ScrollController build(BuildContext context) => _scrollController;

  @override
  void dispose() => _scrollController.dispose();
}

class _TrackingScrollControllerHook extends Hook<TrackingScrollController> {
  final String debugLabel;
  final double initialScrollOffset;
  final bool keepScrollOffset;

  const _TrackingScrollControllerHook({
    this.debugLabel,
    this.initialScrollOffset,
    this.keepScrollOffset,
    List keys,
  }) : super(keys: keys);

  @override
  _TrackingScrollControllerHookState createState() =>
      _TrackingScrollControllerHookState();
}

class _TrackingScrollControllerHookState
    extends HookState<TrackingScrollController, _TrackingScrollControllerHook> {
  TrackingScrollController _trackingScrollController;

  @override
  void initHook() {
    _trackingScrollController = TrackingScrollController(
      initialScrollOffset: hook.initialScrollOffset,
      keepScrollOffset: hook.keepScrollOffset,
      debugLabel: hook.debugLabel,
    );
  }

  @override
  TrackingScrollController build(BuildContext context) =>
      _trackingScrollController;

  @override
  void dispose() => _trackingScrollController.dispose();
}

/// Creates an [TextEditingController] automatically disposed.
///
/// Changing the [text] parameter automatically updates [TextEditingController.text].
///
/// See also:
///   * [TextEditingController]
TextEditingController useTextEditingController({
  String text,
  List keys,
}) {
  return Hook.use(_TextEditingControllerHook(
    text: text,
    keys: keys,
  ));
}

class _TextEditingControllerHook extends Hook<TextEditingController> {
  final String text;

  const _TextEditingControllerHook({
    this.text,
    List keys,
  }) : super(keys: keys);

  @override
  _TextEditingControllerHookState createState() =>
      _TextEditingControllerHookState();
}

class _TextEditingControllerHookState
    extends HookState<TextEditingController, _TextEditingControllerHook> {
  TextEditingController _textEditingController;

  @override
  void didUpdateHook(_TextEditingControllerHook oldHook) {
    if (hook.text != oldHook.text) {
      _textEditingController.text = hook.text;
    }
  }

  @override
  void initHook() => _textEditingController = TextEditingController(
        text: hook.text,
      );

  @override
  TextEditingController build(BuildContext context) => _textEditingController;

  @override
  void dispose() => _textEditingController.dispose();
}

/// Creates an [PageController] automatically disposed.
///
/// [initialPage], [viewportFraction] and [keepPage] are ignored after the first call.
///
/// See also:
///   * [PageController]
PageController usePageController({
  int initialPage = 0,
  double viewportFraction = 1.0,
  bool keepPage = true,
  List keys,
}) {
  return Hook.use(_PageControllerHook(
    initialPage: initialPage,
    viewportFraction: viewportFraction,
    keepPage: keepPage,
    keys: keys,
  ));
}

class _PageControllerHook extends Hook<PageController> {
  final int initialPage;
  final double viewportFraction;
  final bool keepPage;

  const _PageControllerHook({
    this.initialPage,
    this.viewportFraction,
    this.keepPage,
    List keys,
  }) : super(keys: keys);

  @override
  _PageControllerHookState createState() => _PageControllerHookState();
}

class _PageControllerHookState
    extends HookState<PageController, _PageControllerHook> {
  PageController _pageController;

  @override
  void initHook() => _pageController = PageController(
        initialPage: hook.initialPage,
        keepPage: hook.keepPage,
        viewportFraction: hook.viewportFraction,
      );

  @override
  PageController build(BuildContext context) => _pageController;

  @override
  void dispose() => _pageController.dispose();
}

/// Defines how a value is interpolated between a [from] value and a [to] value
/// at the given [time].
typedef T TweenLerp<T extends dynamic>(T from, T to, double time);

/// Creates a [Tween] for interpolating a value.
///
/// See also:
///   * [Tween]
final useTween = UseTween();

/// Using various [Tween]s.
///
/// See also:
///   * [call]
///   * [color]
class UseTween {
  /// Creates a new [Tween] for interpolating a [value] with the previous one according
  /// to a [lerp] function.
  ///
  /// Each time the [value] changed, a new [Tween] is returned with its [Tween.begin] affected to
  /// the previous [value] and its [Tween.end] affected to the current [value].
  ///
  /// If no [lerp] function is given, a default [Tween] is used.
  ///
  /// At first call, [Tween.begin] and [Tween.end] have the initial [value].
  ///
  /// See also:
  ///   * [Tween]
  ///   * [TweenLerp]
  Tween<T> call<T extends dynamic>(T value, {TweenLerp<T> lerp}) {
    return Hook.use(_TweenHook<T>(
      value: value,
      builder: lerp == null ? null : (begin,end) => _CustomTween(begin: begin, end: end, lerp: lerp),
    ));
  }

  /// Creates a new [Tween] for interpolating a [Color].
  ///
  /// See also:
  ///   * [call]
  ///   * [Color]
  Tween<Color> color(Color value) {
    return Hook.use(_TweenHook<Color>(
      value: value,
      builder: (begin, end) => ColorTween(begin: begin, end: end),
    ));
  }

  /// Creates a new [Tween] for interpolating an [EdgeInsets].
  ///
  /// See also:
  ///   * [call]
  ///   * [EdgeInsets]
  Tween<EdgeInsets> edgeInsets(EdgeInsets value) {
    return Hook.use(_TweenHook<EdgeInsets>(
      value: value,
      builder: (begin, end) => EdgeInsetsTween(begin: begin, end: end),
    ));
  }

  /// Creates a new [Tween] for interpolating a [TextStyle].
  ///
  /// See also:
  ///   * [call]
  ///   * [TextStyle]
  Tween<TextStyle> textStyle(TextStyle value) {
    return Hook.use(_TweenHook<TextStyle>(
      value: value,
      builder: (begin, end) => TextStyleTween(begin: begin, end: end),
    ));
  }

  /// Creates a new [Tween] for interpolating a [Border].
  ///
  /// See also:
  ///   * [call]
  ///   * [Border]
  Tween<Border> border(Border value) {
    return Hook.use(_TweenHook<Border>(
      value: value,
      builder: (begin, end) => BorderTween(begin: begin, end: end),
    ));
  }

  /// Creates a new [Tween] for interpolating an [Alignment].
  ///
  /// See also:
  ///   * [call]
  ///   * [Alignment]
  Tween<Alignment> alignment(Alignment value) {
    return Hook.use(_TweenHook<Alignment>(
      value: value,
      builder: (begin, end) => AlignmentTween(begin: begin, end: end),
    ));
  }

  /// Creates a new [Tween] for interpolating an [Alignment].
  ///
  /// See also:
  ///   * [call]
  ///   * [BorderRadius]
  Tween<BorderRadius> borderRadius(BorderRadius value) {
    return Hook.use(_TweenHook<BorderRadius>(
      value: value,
      builder: (begin, end) => BorderRadiusTween(begin: begin, end: end),
    ));
  }

  /// Creates a new [Tween] for interpolating an [BoxConstraints].
  ///
  /// See also:
  ///   * [call]
  ///   * [BoxConstraints]
  Tween<BoxConstraints> boxConstraints(BoxConstraints value) {
    return Hook.use(_TweenHook<BoxConstraints>(
      value: value,
      builder: (begin, end) => BoxConstraintsTween(begin: begin, end: end),
    ));
  }

  /// Creates a new [Tween] for interpolating an [Size].
  ///
  /// See also:
  ///   * [call]
  ///   * [Size]
  Tween<Size> size(Size value) {
    return Hook.use(_TweenHook<Size>(
      value: value,
      builder: (begin, end) => SizeTween(begin: begin, end: end),
    ));
  }

  /// Creates a new [Tween] for interpolating an [Rect].
  ///
  /// See also:
  ///   * [call]
  ///   * [Rect]
  Tween<Rect> rect(Rect value) {
    return Hook.use(_TweenHook<Rect>(
      value: value,
      builder: (begin, end) => RectTween(begin: begin, end: end),
    ));
  }

  /// Creates a new [Tween] for interpolating an [RelativeRect].
  ///
  /// See also:
  ///   * [call]
  ///   * [RelativeRect]
  Tween<RelativeRect> relativeRect(RelativeRect value) {
    return Hook.use(_TweenHook<RelativeRect>(
      value: value,
      builder: (begin, end) => RelativeRectTween(begin: begin, end: end),
    ));
  }
}

typedef Tween<T> _TweenBuilder<T extends dynamic>(T begin, T end);

class _TweenHook<T> extends Hook<Tween<T>> {
  final T value;
  final _TweenBuilder<T> builder;

  const _TweenHook({
    this.value,
    this.builder,
    List keys,
  }) : super(keys: keys);

  @override
  _TweenHookState<T> createState() => _TweenHookState<T>();
}

class _CustomTween<T extends dynamic> extends Tween<T> {
  final TweenLerp<T> _lerp;
  _CustomTween({T begin, T end, TweenLerp<T> lerp})
      : _lerp = lerp,
        super(begin: begin, end: end);

  @override
  T lerp(double t) => this._lerp(begin, end, t);
}

class _TweenHookState<T> extends HookState<Tween<T>, _TweenHook<T>> {
  Tween<T> _tween;

  Tween<T> _createTween(T begin) {
    if (hook.builder != null) {
      return hook.builder(begin, hook.value);
    }

    return Tween<T>(begin: begin, end: hook.value);
  }

  @override
  void initHook() => _tween = _createTween(hook.value);

  @override
  void didUpdateHook(_TweenHook<T> oldHook) {
    if (hook.value != oldHook.value ||
        hook.builder != oldHook.builder) {
      _tween = _createTween(oldHook.value);
    }
  }

  @override
  Tween<T> build(BuildContext context) => _tween;
}
