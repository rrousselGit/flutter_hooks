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
  const _ReducerdHook(this.reducer, {this.initialState, this.initialAction})
      : assert(reducer != null, 'reducer cannot be null');

  final Reducer<State, Action> reducer;
  final State initialState;
  final Action initialAction;

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
    // TODO support null
    assert(state != null, 'reducers cannot return null');
  }

  @override
  void dispatch(Action action) {
    final newState = hook.reducer(state, action);
    assert(newState != null, 'recuders cannot return null');
    if (state != newState) {
      setState(() => state = newState);
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
  const _PreviousHook(this.value);

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
  }(), '');
}

class _ReassembleHook extends Hook<void> {
  const _ReassembleHook(this.callback) : assert(callback != null, 'callback cannot be null');

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
}
