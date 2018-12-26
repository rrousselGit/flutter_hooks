part of 'hook.dart';

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
  const _TickerProviderHook([List keys]) : super(keys: keys);

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
  AnimationController build(HookContext context) {
    final vsync =
        hook.vsync ?? context.useSingleTickerProvider(keys: hook.keys);

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
  void build(HookContext context) {}

  void _listener() {
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    hook.listenable.removeListener(_listener);
  }
}

class _FutureHook<T> extends Hook<AsyncSnapshot<T>> {
  final Future<T> future;
  final T initialData;

  const _FutureHook(this.future, {this.initialData});

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
        _snapshot = _snapshot.inState(ConnectionState.none);
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
  AsyncSnapshot<T> build(HookContext context) {
    return _snapshot;
  }
}

class _StreamHook<T> extends Hook<AsyncSnapshot<T>> {
  final Stream<T> stream;
  final T initialData;

  _StreamHook(this.stream, {this.initialData});

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
        _summary = afterDisconnected(_summary);
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
  AsyncSnapshot<T> build(HookContext context) {
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

class _EffectHook extends Hook<void> {
  final VoidCallback Function() effect;

  const _EffectHook(this.effect, [List keys])
      : assert(effect != null),
        super(keys: keys);

  @override
  _EffectHookState createState() => _EffectHookState();
}

class _EffectHookState extends HookState<void, _EffectHook> {
  VoidCallback disposer;

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
  void build(HookContext context) {}

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
  StreamController<T> build(HookContext context) {
    return _controller;
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}
