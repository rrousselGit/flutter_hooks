part of 'hooks.dart';

/// Subscribes to a [Future] and return its current state in an [AsyncSnapshot].
///
/// * [preserveState] defines if the current value should be preserved when changing
/// the [Future] instance.
///
/// See also:
///   * [Future], the listened object.
///   * [useStream], similar to [useFuture] but for [Stream].
AsyncSnapshot<T> useFuture<T>(Future<T> future,
    {T? initialData, bool preserveState = true}) {
  return use(_FutureHook(future,
      initialData: initialData, preserveState: preserveState));
}

class _FutureHook<T> extends Hook<AsyncSnapshot<T>> {
  const _FutureHook(this.future, {this.initialData, this.preserveState = true});

  final Future<T> future;
  final bool preserveState;
  final T? initialData;

  @override
  _FutureStateHook<T> createState() => _FutureStateHook<T>();
}

class _FutureStateHook<T> extends HookState<AsyncSnapshot<T>, _FutureHook<T>> {
  /// An object that identifies the currently active callbacks. Used to avoid
  /// calling setState from stale callbacks, e.g. after disposal of this state,
  /// or after widget reconfiguration to a new Future.
  Object? _activeCallbackIdentity;
  late AsyncSnapshot<T> _snapshot;

  @override
  void initHook() {
    super.initHook();
    if (hook.initialData != null) {
      _snapshot = AsyncSnapshot<T>.withData(
          ConnectionState.none, hook.initialData as T);
    } else {
      _snapshot = AsyncSnapshot<T>.nothing();
    }
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
          if (hook.initialData != null) {
            _snapshot = AsyncSnapshot<T>.withData(
                ConnectionState.none, hook.initialData as T);
          } else {
            _snapshot = AsyncSnapshot<T>.nothing();
          }
        }
      }
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
  }

  void _subscribe() {
    final callbackIdentity = Object();
    _activeCallbackIdentity = callbackIdentity;
    hook.future.then<void>((data) {
      if (_activeCallbackIdentity == callbackIdentity) {
        setState(() {
          _snapshot = AsyncSnapshot<T>.withData(ConnectionState.done, data);
        });
      }
    }, onError: (dynamic error) {
      if (_activeCallbackIdentity == callbackIdentity) {
        setState(() {
          _snapshot =
              AsyncSnapshot<T>.withError(ConnectionState.done, error as Object);
        });
      }
    });
    _snapshot = _snapshot.inState(ConnectionState.waiting);
  }

  void _unsubscribe() {
    _activeCallbackIdentity = null;
  }

  @override
  AsyncSnapshot<T> build(BuildContext context) {
    return _snapshot;
  }

  @override
  String get debugLabel => 'useFuture';

  @override
  Object get debugValue => _snapshot;
}

/// Subscribes to a [Stream] and return its current state in an [AsyncSnapshot].
///
/// See also:
///   * [Stream], the object listened.
///   * [useFuture], similar to [useStream] but for [Future].
AsyncSnapshot<T> useStream<T>(Stream<T> stream,
    {T? initialData, bool preserveState = true}) {
  return use(_StreamHook(
    stream,
    initialData: initialData,
    preserveState: preserveState,
  ));
}

class _StreamHook<T> extends Hook<AsyncSnapshot<T>> {
  const _StreamHook(this.stream, {this.initialData, this.preserveState = true});

  final Stream<T> stream;
  final T? initialData;
  final bool preserveState;

  @override
  _StreamHookState<T> createState() => _StreamHookState<T>();
}

/// a clone of [StreamBuilderBase] implementation
class _StreamHookState<T> extends HookState<AsyncSnapshot<T>, _StreamHook<T>> {
  StreamSubscription<T>? _subscription;
  late AsyncSnapshot<T> _summary;

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
  }

  void _subscribe() {
    _subscription = hook.stream.listen((data) {
      setState(() {
        _summary = afterData(_summary, data);
      });
    }, onError: (dynamic error) {
      setState(() {
        _summary = afterError(_summary, error as Object);
      });
    }, onDone: () {
      setState(() {
        _summary = afterDone(_summary);
      });
    });
    _summary = afterConnected(_summary);
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  AsyncSnapshot<T> build(BuildContext context) {
    return _summary;
  }

  AsyncSnapshot<T> initial() => hook.initialData != null
      ? AsyncSnapshot<T>.withData(ConnectionState.none, hook.initialData as T)
      : AsyncSnapshot<T>.nothing();

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

  @override
  String get debugLabel => 'useStream';
}

/// Creates a [StreamController] automatically disposed.
///
/// See also:
///   * [StreamController], the created object
///   * [useStream], to listen to the created [StreamController]
StreamController<T> useStreamController<T>(
    {bool sync = false,
    VoidCallback? onListen,
    VoidCallback? onCancel,
    List<Object>? keys}) {
  return use(_StreamControllerHook(
    onCancel: onCancel,
    onListen: onListen,
    sync: sync,
    keys: keys,
  ));
}

class _StreamControllerHook<T> extends Hook<StreamController<T>> {
  const _StreamControllerHook(
      {this.sync = false, this.onListen, this.onCancel, List<Object>? keys})
      : super(keys: keys);

  final bool sync;
  final VoidCallback? onListen;
  final VoidCallback? onCancel;

  @override
  _StreamControllerHookState<T> createState() =>
      _StreamControllerHookState<T>();
}

class _StreamControllerHookState<T>
    extends HookState<StreamController<T>, _StreamControllerHook<T>> {
  late StreamController<T> _controller;

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
  }

  @override
  String get debugLabel => 'useStreamController';
}
