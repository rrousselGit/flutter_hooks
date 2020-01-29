part of 'hooks.dart';

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

/// Returns the previous argument called to [usePrevious].
T usePrevious<T>(T val) {
  return Hook.use(_PreviousHook(val));
}

class _PreviousHook<T> extends Hook<T> {
  _PreviousHook(this.value);

  final T value;

  @override
  _PreviousHookState<T> createState() => _PreviousHookState();
}

class _PreviousHookState<T> extends HookState<T, _PreviousHook<T>> {
  T previous;

  @override
  void didUpdateHook(_PreviousHook<T> old) {
    previous = old.value;
  }

  @override
  T build(BuildContext context) => previous;
}

/// Runs the callback on every hot reload
/// similar to reassemble in the Stateful widgets
///
/// See also:
///
///  * [State.reassemble]
void useReassemble(VoidCallback callback) {
  assert(() {
    Hook.use(_ReassembleHook(callback));
    return true;
  }());
}

class _ReassembleHook extends Hook<void> {
  final VoidCallback callback;

  _ReassembleHook(this.callback) : assert(callback != null);

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
}

/// Allows subtrees to request to be kept alive in lazy lists.
///
/// See also:
///
///  * [AutomaticKeepAlive]
///  * [AutomaticKeepAliveClientMixin]
void useAutomaticKeepAliveClient({bool wantKeepAlive = true}) {
  Hook.use(_AutomaticKeepAliveClientHook(wantKeepAlive));
}

class _AutomaticKeepAliveClientHook extends Hook<void> {
  final bool wantKeepAlive;

  _AutomaticKeepAliveClientHook(this.wantKeepAlive)
      : assert(wantKeepAlive != null);

  @override
  _AutomaticKeepAliveClientHookState createState() =>
      _AutomaticKeepAliveClientHookState();
}

class _AutomaticKeepAliveClientHookState
    extends HookState<void, _AutomaticKeepAliveClientHook> {
  KeepAliveHandle _keepAliveHandle;

  bool get wantKeepAlive => hook.wantKeepAlive;

  void _ensureKeepAlive() {
    assert(_keepAliveHandle == null);
    _keepAliveHandle = KeepAliveHandle();
    KeepAliveNotification(_keepAliveHandle).dispatch(context);
  }

  void _releaseKeepAlive() {
    _keepAliveHandle.release();
    _keepAliveHandle = null;
  }

  /// Ensures that any [AutomaticKeepAlive] ancestors are in a good state, by
  /// firing a [KeepAliveNotification] or triggering the [KeepAliveHandle] as
  /// appropriate.
  @protected
  void updateKeepAlive() {
    if (wantKeepAlive) {
      if (_keepAliveHandle == null) _ensureKeepAlive();
    } else {
      if (_keepAliveHandle != null) _releaseKeepAlive();
    }
  }

  @override
  initHook() {
    super.initHook();
    if (wantKeepAlive) _ensureKeepAlive();
  }

  @override
  void deactivate() {
    if (_keepAliveHandle != null) _releaseKeepAlive();
    super.deactivate();
  }

  @override
  void build(BuildContext context) {
    if (wantKeepAlive && _keepAliveHandle == null) _ensureKeepAlive();
  }
}
