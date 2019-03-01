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
