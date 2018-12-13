part of 'hook.dart';

// class _StreamHook<T> extends Hook<AsyncSnapshot<T>> {
//   final Stream<T> stream;
//   final T initialData;
//   _StreamHook({this.stream, this.initialData});

//   @override
//   _StreamHookState<T> createState() => _StreamHookState<T>();
// }

// class _StreamHookState<T> extends HookState<AsyncSnapshot<T>, _StreamHook<T>> {
//   StreamSubscription<T> subscription;
//   AsyncSnapshot<T> snapshot;
//   @override
//   void initHook() {
//     super.initHook();
//     _listen(hook.stream);
//   }

//   @override
//   void didUpdateHook(_StreamHook oldHook) {
//     super.didUpdateHook(oldHook);
//     if (oldHook.stream != hook.stream) {
//       _listen(hook.stream);
//     }
//   }

//   void _listen(Stream<T> stream) {
//     subscription?.cancel();
//     snapshot = stream == null
//         ? AsyncSnapshot<T>.nothing()
//         : AsyncSnapshot<T>.withData(ConnectionState.waiting, hook.initialData);
//     subscription =
//         hook.stream.listen(_onData, onDone: _onDone, onError: _onError);
//   }

//   void _onData(T event) {
//     setState(() {
//       snapshot = AsyncSnapshot<T>.withData(ConnectionState.active, event);
//     });
//   }

//   void _onDone() {
//     setState(() {
//       snapshot = snapshot.hasError
//           ? AsyncSnapshot<T>.withError(ConnectionState.active, snapshot.error)
//           : AsyncSnapshot<T>.withData(ConnectionState.done, snapshot.data);
//     });
//   }

//   void _onError(Object error) {
//     setState(() {
//       snapshot = AsyncSnapshot<T>.withError(ConnectionState.active, error);
//     });
//   }

//   @override
//   void dispose() {
//     subscription?.cancel();
//     super.dispose();
//   }

//   @override
//   AsyncSnapshot<T> build(HookContext context) {
//     return snapshot;
//   }
// }

// class _TickerProviderHook extends Hook<TickerProvider> {
//   const _TickerProviderHook();

//   @override
//   _TickerProviderHookState createState() => _TickerProviderHookState();
// }

// class _TickerProviderHookState
//     extends HookState<TickerProvider, _TickerProviderHook>
//     implements TickerProvider {
//   Ticker _ticker;

//   @override
//   Ticker createTicker(TickerCallback onTick) {
//     assert(() {
//       if (_ticker == null) return true;
//       // TODO: update error
//       throw FlutterError(
//           '$runtimeType is a SingleTickerProviderStateMixin but multiple tickers were created.\n'
//           'A SingleTickerProviderStateMixin can only be used as a TickerProvider once. If a '
//           'State is used for multiple AnimationController objects, or if it is passed to other '
//           'objects and those objects might use it more than one time in total, then instead of '
//           'mixing in a SingleTickerProviderStateMixin, use a regular TickerProviderStateMixin.');
//     }());
//     _ticker = Ticker(onTick, debugLabel: 'created by $this');
//     // TODO: check if the following is still valid
//     // We assume that this is called from initState, build, or some sort of
//     // event handler, and that thus TickerMode.of(context) would return true. We
//     // can't actually check that here because if we're in initState then we're
//     // not allowed to do inheritance checks yet.
//     return _ticker;
//   }

//   @override
//   void dispose() {
//     assert(() {
//       if (_ticker == null || !_ticker.isActive) return true;
//       // TODO: update error
//       throw FlutterError('$this was disposed with an active Ticker.\n'
//           '$runtimeType created a Ticker via its SingleTickerProviderStateMixin, but at the time '
//           'dispose() was called on the mixin, that Ticker was still active. The Ticker must '
//           'be disposed before calling super.dispose(). Tickers used by AnimationControllers '
//           'should be disposed by calling dispose() on the AnimationController itself. '
//           'Otherwise, the ticker will leak.\n'
//           'The offending ticker was: ${_ticker.toString(debugIncludeStack: true)}');
//     }());
//     super.dispose();
//   }

//   @override
//   TickerProvider build(HookContext context) {
//     if (_ticker != null) _ticker.muted = !TickerMode.of(context);

//     return this;
//   }
// }

// class _AnimationControllerHook extends Hook<AnimationController> {
//   final Duration duration;

//   const _AnimationControllerHook({this.duration});

//   @override
//   _AnimationControllerHookState createState() =>
//       _AnimationControllerHookState();
// }

// class _AnimationControllerHookState
//     extends HookState<AnimationController, _AnimationControllerHook> {
//   TickerProvider _ticker;
//   AnimationController animationController;

//   @override
//   void dispose() {
//     super.dispose();
//     animationController?.dispose();
//     super.dispose();
//   }

//   @override
//   void didUpdateHook(_AnimationControllerHook oldHook) {
//     super.didUpdateHook(oldHook);
//     if (hook.duration != oldHook.duration) {
//       animationController?.duration = hook.duration;
//     }
//   }

//   @override
//   AnimationController build(HookContext context) {
//     final ticker = context.useTickerProvider();
//     if (ticker != _ticker) {
//       _ticker = ticker;
//       animationController.resync(_ticker);
//       animationController =
//           AnimationController(vsync: ticker, duration: hook.duration);
//     }

//     return animationController;
//   }
// }

// class _MemoizedHook<T> extends Hook<T> {
//   final T Function() valueBuilder;
//   final void Function(T value) dispose;
//   final List parameters;

//   const _MemoizedHook(this.valueBuilder,
//       {this.parameters = const [], this.dispose})
//       : assert(valueBuilder != null),
//         assert(parameters != null);

//   @override
//   _MemoizedHookState<T> createState() => _MemoizedHookState<T>();
// }

// class _MemoizedHookState<T> extends HookState<T, _MemoizedHook<T>> {
//   T value;

//   @override
//   void initHook() {
//     super.initHook();
//     value = hook.valueBuilder();
//   }

//   @override
//   void didUpdateHook(_MemoizedHook<T> oldHook) {
//     super.didUpdateHook(oldHook);
//     if (hook.parameters != oldHook.parameters &&
//         (hook.parameters.length != oldHook.parameters.length ||
//             _hasDiffWith(oldHook.parameters))) {
//       if (hook.dispose != null) {
//         hook.dispose(value);
//       }
//       value = hook.valueBuilder();
//     }
//   }

//   @override
//   void dispose() {
//     if (hook.dispose != null) {
//       hook.dispose(value);
//     }
//     super.dispose();
//   }

//   bool _hasDiffWith(List parameters) {
//     for (var i = 0; i < parameters.length; i++) {
//       if (parameters[i] != hook.parameters[i]) {
//         return true;
//       }
//     }
//     return false;
//   }

//   @override
//   T build(HookContext context) {
//     return value;
//   }
// }

// class _ValueChangedHook<T, R> extends Hook<R> {
//   final R Function(T oldValue, R oldResult) valueChanged;
//   final T value;

//   const _ValueChangedHook(this.value, this.valueChanged)
//       : assert(valueChanged != null);

//   @override
//   _ValueChangedHookState<T, R> createState() => _ValueChangedHookState<T, R>();
// }

// class _ValueChangedHookState<T, R>
//     extends HookState<R, _ValueChangedHook<T, R>> {
//   R _result;

//   @override
//   void didUpdateHook(_ValueChangedHook<T, R> oldHook) {
//     super.didUpdateHook(oldHook);
//     if (hook.value != oldHook.value) {
//       _result = hook.valueChanged(oldHook.value, _result);
//     }
//   }

//   @override
//   R build(HookContext context) {
//     return _result;
//   }
// }

// class _AnimationHook<T> extends Hook<T> {
//   final Animation<T> animation;

//   const _AnimationHook(this.animation) : assert(animation != null);

//   @override
//   _AnimationHookState<T> createState() => _AnimationHookState<T>();
// }

// class _AnimationHookState<T> extends HookState<T, _AnimationHook<T>> {
//   @override
//   void initHook() {
//     super.initHook();
//     hook.animation.addListener(_listener);
//   }

//   @override
//   void dispose() {
//     hook.animation.removeListener(_listener);
//     super.dispose();
//   }

//   @override
//   T build(HookContext context) {
//     context.useValueChanged(hook.animation, valueChange);
//     return hook.animation.value;
//   }

//   void _listener() {
//     setState(() {});
//   }

//   void valueChange(Animation<T> previous, _) {
//     previous.removeListener(_listener);
//     hook.animation.addListener(_listener);
//   }
// }

// class _StateHook<T> extends Hook<ValueNotifier<T>> {
//   final T initialData;
//   final void Function(T value) dispose;

//   const _StateHook({this.initialData, this.dispose});

//   @override
//   _StateHookState<T> createState() => _StateHookState();
// }

// class _StateHookState<T> extends HookState<ValueNotifier<T>, _StateHook<T>> {
//   TickerProvider _ticker;
//   ValueNotifier<T> _state;

//   @override
//   void initHook() {
//     super.initHook();
//     _state = ValueNotifier(hook.initialData)..addListener(_listener);
//   }

//   @override
//   void dispose() {
//     if (hook.dispose != null) {
//       hook.dispose(_state.value);
//     }
//     _state.dispose();
//     super.dispose();
//   }

//   @override
//   ValueNotifier<T> build(HookContext context) {
//     return _state;
//   }

//   void _listener() {
//     setState(() {});
//   }
// }

class HookBuilder extends HookWidget {
  final Widget Function(HookContext context) builder;

  const HookBuilder({
    @required this.builder,
    Key key,
  })  : assert(builder != null),
        super(key: key);

  @override
  Widget build(HookContext context) => builder(context);
}
