part of 'hooks.dart';

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
