part of 'hooks.dart';

/// A store of mutable state that allows mutations by dispatching actions.
abstract class Store<StateT, ActionT> {
  /// The current state.
  ///
  /// This value may change after a call to [dispatch].
  StateT get state;

  /// Dispatches an action.
  ///
  /// Actions are dispatched synchronously.
  /// It is impossible to try to dispatch actions during `build`.
  void dispatch(ActionT action);
}

/// Composes an [Action] and a [State] to create a new [State].
///
/// [Reducer] must never return `null`, even if [state] or [action] are `null`.
typedef Reducer<State, Action> = State Function(State state, Action action);

/// An alternative to [useState] for more complex states.
///
/// [useReducer] manages a read only instance of state that can be updated
/// by dispatching actions which are interpreted by a [Reducer].
///
/// [reducer] is immediately called on first build with [initialAction]
/// and [initialState] as parameter.
///
/// It is possible to change the [reducer] by calling [useReducer]
/// with a new [Reducer].
///
/// See also:
///  * [Reducer]
///  * [Store]
Store<StateT, ActionT> useReducer<StateT, ActionT>(
  Reducer<StateT, ActionT> reducer, {
  required StateT initialState,
  required ActionT initialAction,
}) {
  return use(
    _ReducerHook(
      reducer,
      initialAction: initialAction,
      initialState: initialState,
    ),
  );
}

class _ReducerHook<StateT, ActionT> extends Hook<Store<StateT, ActionT>> {
  const _ReducerHook(
    this.reducer, {
    required this.initialState,
    required this.initialAction,
  });

  final Reducer<StateT, ActionT> reducer;
  final StateT initialState;
  final ActionT initialAction;

  @override
  _ReducerHookState<StateT, ActionT> createState() =>
      _ReducerHookState<StateT, ActionT>();
}

class _ReducerHookState<StateT, ActionT>
    extends HookState<Store<StateT, ActionT>, _ReducerHook<StateT, ActionT>>
    implements Store<StateT, ActionT> {
  @override
  late StateT state = hook.reducer(hook.initialState, hook.initialAction);

  @override
  void initHook() {
    super.initHook();
    // ignore: unnecessary_statements, Force the late variable to compute
    state;
  }

  @override
  void dispatch(ActionT action) {
    final newState = hook.reducer(state, action);

    if (state != newState) {
      setState(() => state = newState);
    }
  }

  @override
  Store<StateT, ActionT> build(BuildContext context) {
    return this;
  }

  @override
  String get debugLabel => 'useReducer';

  @override
  Object? get debugValue => state;
}

/// Returns the previous value passed to [usePrevious] (from the previous widget `build`).
T? usePrevious<T>(T val) {
  return use(_PreviousHook(val));
}

class _PreviousHook<T> extends Hook<T?> {
  const _PreviousHook(this.value);

  final T value;

  @override
  _PreviousHookState<T> createState() => _PreviousHookState();
}

class _PreviousHookState<T> extends HookState<T?, _PreviousHook<T>> {
  T? previous;

  @override
  void didUpdateHook(_PreviousHook<T> old) {
    previous = old.value;
  }

  @override
  T? build(BuildContext context) => previous;

  @override
  String get debugLabel => 'usePrevious';

  @override
  Object? get debugValue => previous;
}

/// Runs the callback on every hot reload,
/// similar to `reassemble` in the stateful widgets.
///
/// See also:
///
///  * [State.reassemble]
void useReassemble(VoidCallback callback) {
  assert(() {
    use(_ReassembleHook(callback));
    return true;
  }(), '');
}

class _ReassembleHook extends Hook<void> {
  const _ReassembleHook(this.callback);

  final VoidCallback callback;

  @override
  _ReassembleHookState createState() => _ReassembleHookState();
}

class _ReassembleHookState extends HookState<void, _ReassembleHook> {
  @override
  void reassemble() {
    super.reassemble();
    hook.callback();
  }

  @override
  void build(BuildContext context) {}

  @override
  String get debugLabel => 'useReassemble';

  @override
  bool get debugSkipValue => true;
}

/// Returns an [IsMounted] object that you can use
/// to check if the [State] is mounted.
///
/// ```dart
/// final isMounted = useIsMounted();
/// useEffect((){
///   myFuture.then((){
///     if (isMounted()) {
///       // Do something
///     }
///   });
/// }, []);
/// ```
///
/// See also:
///   * The [State.mounted] property.
@Deprecated(
  "Use BuildContext.mounted instead if you're on Flutter 3.7.0 or greater",
)
IsMounted useIsMounted() {
  return use(const _IsMountedHook());
}

// ignore: deprecated_member_use_from_same_package
class _IsMountedHook extends Hook<IsMounted> {
  const _IsMountedHook();

  @override
  _IsMountedHookState createState() => _IsMountedHookState();
}

// ignore: deprecated_member_use_from_same_package
class _IsMountedHookState extends HookState<IsMounted, _IsMountedHook> {
  bool _mounted = true;

  @override
  // ignore: deprecated_member_use_from_same_package
  IsMounted build(BuildContext context) => _isMounted;

  bool _isMounted() => _mounted;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  @override
  String get debugLabel => 'useIsMounted';

  @override
  Object? get debugValue => _mounted;
}

// ignore: deprecated_member_use_from_same_package
/// Used by [useIsMounted] to allow widgets to determine if the [Widget] is still
/// in the widget tree or not.
@Deprecated(
  "Use BuildContext.mounted instead if you're on Flutter 3.7.0 or greater",
)
typedef IsMounted = bool Function();

/// Creates a [OverlayPortalController] that will be disposed automatically.
///
/// See also:
/// - [OverlayPortalController]
OverlayPortalController useOverlayPortalController({
  List<Object?>? keys,
}) {
  return use(_OverlayPortalControllerHook(keys: keys));
}

class _OverlayPortalControllerHook extends Hook<OverlayPortalController> {
  const _OverlayPortalControllerHook({List<Object?>? keys}) : super(keys: keys);

  @override
  HookState<OverlayPortalController, Hook<OverlayPortalController>>
      createState() => _OverlayPortalControllerHookState();
}

class _OverlayPortalControllerHookState
    extends HookState<OverlayPortalController, _OverlayPortalControllerHook> {
  final controller = OverlayPortalController();

  @override
  OverlayPortalController build(BuildContext context) => controller;

  @override
  String get debugLabel => 'useOverlayPortalController';
}
