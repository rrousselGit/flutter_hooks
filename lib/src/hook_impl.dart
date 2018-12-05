part of 'hook.dart';

class _StreamHook<T> extends Hook {
  final Stream<T> stream;
  final T initialData;
  _StreamHook({this.stream, this.initialData});
  @override
  HookState<Hook> createState() => _StreamHookState<T>();
}

class _StreamHookState<T> extends HookState<_StreamHook<T>> {
  StreamSubscription<T> subscription;
  AsyncSnapshot<T> snapshot;
  @override
  void initHook() {
    _listen(hook.stream);
  }

  @override
  void didUpdateHook(_StreamHook oldHook) {
    if (oldHook.stream != hook.stream) {
      _listen(hook.stream);
    }
  }

  void _listen(Stream<T> stream) {
    subscription?.cancel();
    snapshot = stream == null
        ? AsyncSnapshot<T>.nothing()
        : AsyncSnapshot<T>.withData(ConnectionState.waiting, hook.initialData);
    subscription =
        hook.stream.listen(_onData, onDone: _onDone, onError: _onError);
  }

  void _onData(T event) {
    setState(() {
      snapshot = AsyncSnapshot<T>.withData(ConnectionState.active, event);
    });
  }

  void _onDone() {
    setState(() {
      snapshot = snapshot.hasError
          ? AsyncSnapshot<T>.withError(ConnectionState.active, snapshot.error)
          : AsyncSnapshot<T>.withData(ConnectionState.done, snapshot.data);
    });
  }

  void _onError(Object error) {
    setState(() {
      snapshot = AsyncSnapshot<T>.withError(ConnectionState.active, error);
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }
}

class _TickerProviderHook extends Hook {
  const _TickerProviderHook();

  @override
  HookState<Hook> createState() => _TickerProviderHookState();
}

class _TickerProviderHookState extends HookState<_TickerProviderHook>
    implements TickerProvider {
  Ticker _ticker;

  @override
  Ticker createTicker(TickerCallback onTick) {
    assert(() {
      if (_ticker == null) return true;
      // TODO: update error
      throw FlutterError(
          '$runtimeType is a SingleTickerProviderStateMixin but multiple tickers were created.\n'
          'A SingleTickerProviderStateMixin can only be used as a TickerProvider once. If a '
          'State is used for multiple AnimationController objects, or if it is passed to other '
          'objects and those objects might use it more than one time in total, then instead of '
          'mixing in a SingleTickerProviderStateMixin, use a regular TickerProviderStateMixin.');
    }());
    _ticker = Ticker(onTick, debugLabel: 'created by $this');
    // TODO: check if the following is still valid
    // We assume that this is called from initState, build, or some sort of
    // event handler, and that thus TickerMode.of(context) would return true. We
    // can't actually check that here because if we're in initState then we're
    // not allowed to do inheritance checks yet.
    return _ticker;
  }

  @override
  void dispose() {
    assert(() {
      if (_ticker == null || !_ticker.isActive) return true;
      // TODO: update error
      throw FlutterError('$this was disposed with an active Ticker.\n'
          '$runtimeType created a Ticker via its SingleTickerProviderStateMixin, but at the time '
          'dispose() was called on the mixin, that Ticker was still active. The Ticker must '
          'be disposed before calling super.dispose(). Tickers used by AnimationControllers '
          'should be disposed by calling dispose() on the AnimationController itself. '
          'Otherwise, the ticker will leak.\n'
          'The offending ticker was: ${_ticker.toString(debugIncludeStack: true)}');
    }());
  }

  @override
  void build(HookContext context) {
    if (_ticker != null) _ticker.muted = !TickerMode.of(context);
  }
}

class _AnimationControllerHook extends Hook {
  final Duration duration;

  const _AnimationControllerHook({this.duration});

  @override
  HookState<Hook> createState() => _AnimationControllerHookState();
}

class _AnimationControllerHookState
    extends HookState<_AnimationControllerHook> {
  TickerProvider _ticker;
  AnimationController animationController;

  @override
  void dispose() {
    animationController?.dispose();
  }

  @override
  void didUpdateHook(_AnimationControllerHook oldHook) {
    if (hook.duration != oldHook.duration) {
      animationController?.duration = hook.duration;
    }
  }

  @override
  void build(HookContext context) {
    final ticker = context.useTickerProvider();
    if (ticker != _ticker) {
      _ticker = ticker;
      animationController?.dispose();
      animationController =
          AnimationController(vsync: ticker, duration: hook.duration);
    }
  }
}
