part of 'hooks.dart';

/// Subscribes to a [Future] and returns its current state as an [AsyncSnapshot].
///
/// * [preserveState] determines if the current value should be preserved when changing
/// the [Future] instance.
///
/// The [Future] needs to be created outside of [useFuture].
/// If the [Future] is created inside [useFuture], then, every time the build
/// method gets called, the [Future] will be called again. One way to create
/// the [Future] outside of [useFuture] is by using [useMemoized].
///
/// ```dart
/// // BAD
/// useFuture(fetchFromDatabase());
///
/// // GOOD
/// final result = useMemoized(() => fetchFromDatabase());
/// useFuture(result);
/// ```
///
/// See also:
///   * [Future], the listened object.
///   * [useStream], similar to [useFuture] but for [Stream].
AsyncSnapshot<T> useFuture<T>(
  Future<T>? future, {
  T? initialData,
  bool preserveState = true,
}) {
  return use(
    _FutureHook(
      future,
      initialData: initialData,
      preserveState: preserveState,
    ),
  );
}

class _FutureHook<T> extends Hook<AsyncSnapshot<T>> {
  const _FutureHook(
    this.future, {
    required this.initialData,
    this.preserveState = true,
  });

  final Future<T>? future;
  final bool preserveState;
  final T? initialData;

  @override
  _FutureStateHook<T> createState() => _FutureStateHook<T>();
}

class _FutureStateHook<T> extends HookState<AsyncSnapshot<T>, _FutureHook<T>> {
  /// An object that identifies the currently active callbacks. Used to avoid
  /// calling `setState` from stale callbacks, e.g. after disposal of this state,
  /// or after widget reconfiguration to a new [Future].
  Object? _activeCallbackIdentity;
  late AsyncSnapshot<T> _snapshot = initial;

  AsyncSnapshot<T> get initial => hook.initialData == null
      ? AsyncSnapshot<T>.nothing()
      : AsyncSnapshot<T>.withData(ConnectionState.none, hook.initialData as T);

  @override
  void initHook() {
    super.initHook();
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
          _snapshot = initial;
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
    if (hook.future != null) {
      final callbackIdentity = Object();
      _activeCallbackIdentity = callbackIdentity;
      hook.future!.then<void>((data) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withData(ConnectionState.done, data);
          });
        }
        // ignore: avoid_types_on_closure_parameters
      }, onError: (Object error, StackTrace stackTrace) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withError(
              ConnectionState.done,
              error,
              stackTrace,
            );
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

  @override
  String get debugLabel => 'useFuture';

  @override
  Object? get debugValue => _snapshot;
}

/// Subscribes to a [Stream] and returns its current state as an [AsyncSnapshot].
///
/// * [preserveState] determines if the current value should be preserved when changing
/// the [Stream] instance.
///
/// When [preserveState] is true (the default) update jank is reduced when switching
/// streams, but this may result in inconsistent state when using multiple
/// or nested streams. See https://github.com/rrousselGit/flutter_hooks/issues/312
/// for more context.
///
/// See also:
///   * [Stream], the object listened.
///   * [useFuture], similar to [useStream] but for [Future].
AsyncSnapshot<T> useStream<T>(
  Stream<T>? stream, {
  T? initialData,
  bool preserveState = true,
}) {
  return use(
    _StreamHook(
      stream,
      initialData: initialData,
      preserveState: preserveState,
    ),
  );
}

class _StreamHook<T> extends Hook<AsyncSnapshot<T>> {
  const _StreamHook(
    this.stream, {
    required this.initialData,
    required this.preserveState,
  });

  final Stream<T>? stream;
  final T? initialData;
  final bool preserveState;

  @override
  _StreamHookState<T> createState() => _StreamHookState<T>();
}

/// a clone of [StreamBuilderBase] implementation
class _StreamHookState<T> extends HookState<AsyncSnapshot<T>, _StreamHook<T>> {
  StreamSubscription<T>? _subscription;
  late AsyncSnapshot<T> _summary = initial;

  @override
  void initHook() {
    super.initHook();
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
          _summary = initial;
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
    if (hook.stream != null) {
      _subscription = hook.stream!.listen((data) {
        setState(() {
          _summary = afterData(data);
        });
        // ignore: avoid_types_on_closure_parameters
      }, onError: (Object error, StackTrace stackTrace) {
        setState(() {
          _summary = afterError(error, stackTrace);
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
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  AsyncSnapshot<T> build(BuildContext context) {
    return _summary;
  }

  AsyncSnapshot<T> get initial => hook.initialData == null
      ? AsyncSnapshot<T>.nothing()
      : AsyncSnapshot<T>.withData(ConnectionState.none, hook.initialData as T);

  AsyncSnapshot<T> afterConnected(AsyncSnapshot<T> current) =>
      current.inState(ConnectionState.waiting);

  AsyncSnapshot<T> afterData(T data) {
    return AsyncSnapshot<T>.withData(ConnectionState.active, data);
  }

  AsyncSnapshot<T> afterError(Object error, StackTrace stackTrace) {
    return AsyncSnapshot<T>.withError(
      ConnectionState.active,
      error,
      stackTrace,
    );
  }

  AsyncSnapshot<T> afterDone(AsyncSnapshot<T> current) =>
      current.inState(ConnectionState.done);

  AsyncSnapshot<T> afterDisconnected(AsyncSnapshot<T> current) =>
      current.inState(ConnectionState.none);

  @override
  String get debugLabel => 'useStream';
}

/// Creates a [StreamController] which is automatically disposed when necessary.
///
/// See also:
///   * [StreamController], the created object
///   * [useStream], to listen to the created [StreamController]
StreamController<T> useStreamController<T>({
  bool sync = false,
  VoidCallback? onListen,
  VoidCallback? onCancel,
  List<Object?>? keys,
}) {
  return use(
    _StreamControllerHook(
      onCancel: onCancel,
      onListen: onListen,
      sync: sync,
      keys: keys,
    ),
  );
}

class _StreamControllerHook<T> extends Hook<StreamController<T>> {
  const _StreamControllerHook({
    required this.sync,
    this.onListen,
    this.onCancel,
    List<Object?>? keys,
  }) : super(keys: keys);

  final bool sync;
  final VoidCallback? onListen;
  final VoidCallback? onCancel;

  @override
  _StreamControllerHookState<T> createState() =>
      _StreamControllerHookState<T>();
}

class _StreamControllerHookState<T>
    extends HookState<StreamController<T>, _StreamControllerHook<T>> {
  late final _controller = StreamController<T>.broadcast(
    sync: hook.sync,
    onCancel: hook.onCancel,
    onListen: hook.onListen,
  );

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

/// Subscribes to a [Stream] and calls the [Stream.listen] to register the [onData],
/// [onError], and [onDone].
///
/// Returns the [StreamSubscription] returned by the [Stream.listen].
///
/// See also:
///   * [Stream], the object listened.
///   * [Stream.listen], calls the provided handlers.
StreamSubscription<T>? useOnStreamChange<T>(
  Stream<T>? stream, {
  void Function(T event)? onData,
  void Function(Object error, StackTrace stackTrace)? onError,
  void Function()? onDone,
  bool? cancelOnError,
}) {
  return use<StreamSubscription<T>?>(
    _OnStreamChangeHook<T>(
      stream,
      onData: onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    ),
  );
}

class _OnStreamChangeHook<T> extends Hook<StreamSubscription<T>?> {
  const _OnStreamChangeHook(
    this.stream, {
    this.onData,
    this.onError,
    this.onDone,
    this.cancelOnError,
  });

  final Stream<T>? stream;
  final void Function(T event)? onData;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final void Function()? onDone;
  final bool? cancelOnError;

  @override
  _StreamListenerHookState<T> createState() => _StreamListenerHookState<T>();
}

class _StreamListenerHookState<T>
    extends HookState<StreamSubscription<T>?, _OnStreamChangeHook<T>> {
  StreamSubscription<T>? _subscription;

  @override
  void initHook() {
    super.initHook();
    _subscribe();
  }

  @override
  void didUpdateHook(_OnStreamChangeHook<T> oldWidget) {
    super.didUpdateHook(oldWidget);
    if (oldWidget.stream != hook.stream ||
        oldWidget.cancelOnError != hook.cancelOnError) {
      _unsubscribe();
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
  }

  void _subscribe() {
    final stream = hook.stream;
    if (stream != null) {
      _subscription = stream.listen(
        hook.onData,
        onError: hook.onError,
        onDone: hook.onDone,
        cancelOnError: hook.cancelOnError,
      );
    }
  }

  void _unsubscribe() {
    _subscription?.cancel();
  }

  @override
  StreamSubscription<T>? build(BuildContext context) {
    return _subscription;
  }

  @override
  String get debugLabel => 'useOnStreamChange';
}
