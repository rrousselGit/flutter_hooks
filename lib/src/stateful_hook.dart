// @immutable
// abstract class Hook<R> {
//   /// Allows subclasses to have a `const` constructor
//   const Hook();

//   /// Creates the mutable state for this hook linked to its widget creator.
//   ///
//   /// Subclasses should override this method to return a newly created instance of their associated State subclass:
//   ///
//   /// ```
//   /// @override
//   /// HookState createState() => _MyHookState();
//   /// ```
//   ///
//   /// The framework can call this method multiple times over the lifetime of a [HookWidget]. For example,
//   /// if the hook is used multiple times, a separate [HookState] must be created for each usage.
//   @protected
//   HookState<R, Hook<R>> createState();
// }

// /// Tracks the lifecycle of [State] objects when asserts are enabled.
// enum _HookLifecycle {
//   /// The [State] object has been created. [State.initState] is called at this
//   /// time.
//   created,

//   /// The [State.initState] method has been called but the [State] object is
//   /// not yet ready to build. [State.didChangeDependencies] is called at this time.
//   initialized,

//   /// The [State] object is ready to build and [State.dispose] has not yet been
//   /// called.
//   ready,

//   /// The [State.dispose] method has been called and the [State] object is
//   /// no longer able to build.
//   defunct,
// }

// /// The logic and internal state for a [HookWidget]
// ///
// /// A [HookState]
// abstract class HookState<R, T extends Hook<R>> {
//   _HookLifecycle _debugLifecycleState = _HookLifecycle.created;

//   /// Equivalent of [State.context] for [HookState]
//   @protected
//   BuildContext get context => _element;
//   Element _element;

//   /// Equivalent of [State.widget] for [HookState]
//   T get hook => _hook;
//   T _hook;

//   /// Equivalent of [State.initState] for [HookState]
//   @protected
//   @mustCallSuper
//   void initHook() {
//     assert(_debugLifecycleState == _HookLifecycle.created);
//   }

//   /// Equivalent of [State.deactivate] for [HookState]
//   @protected
//   @mustCallSuper
//   void deactivate() {}

//   /// Equivalent of [State.dispose] for [HookState]
//   @protected
//   @mustCallSuper
//   void dispose() {
//     assert(_debugLifecycleState == _HookLifecycle.ready);
//     assert(() {
//       _debugLifecycleState = _HookLifecycle.defunct;
//       return true;
//     }());
//   }

//   /// Called everytimes the [HookState] is requested
//   ///
//   /// [build] is where an [HookState] may use other hooks. This restriction is made to ensure that hooks are unconditionally always requested
//   @protected
//   R build(HookContext context);

//   /// Equivalent of [State.didUpdateWidget] for [HookState]
//   @protected
//   @mustCallSuper
//   void didUpdateHook(covariant Hook oldHook) {}

//   /// Equivalent of [State.setState] for [HookState]
//   @protected
//   void setState(VoidCallback fn) {
//     assert(fn != null);
//     assert(() {
//       if (_debugLifecycleState == _HookLifecycle.defunct) {
//         throw FlutterError('setState() called after dispose(): $this\n'
//             'This error happens if you call setState() on a HookState object for a widget that '
//             'no longer appears in the widget tree (e.g., whose parent widget no longer '
//             'includes the widget in its build). This error can occur when code calls '
//             'setState() from a timer or an animation callback. The preferred solution is '
//             'to cancel the timer or stop listening to the animation in the dispose() '
//             'callback. Another solution is to check the "mounted" property of this '
//             'object before calling setState() to ensure the object is still in the '
//             'tree.\n'
//             'This error might indicate a memory leak if setState() is being called '
//             'because another object is retaining a reference to this State object '
//             'after it has been removed from the tree. To avoid memory leaks, '
//             'consider breaking the reference to this object during dispose().');
//       }
//       if (_debugLifecycleState == _HookLifecycle.created && _element == null) {
//         throw FlutterError('setState() called in constructor: $this\n'
//             'This happens when you call setState() on a HookState object for a widget that '
//             'hasn\'t been inserted into the widget tree yet. It is not necessary to call '
//             'setState() in the constructor, since the state is already assumed to be dirty '
//             'when it is initially created.');
//       }
//       return true;
//     }());
//     final result = fn() as dynamic;
//     assert(() {
//       if (result is Future) {
//         throw FlutterError('setState() callback argument returned a Future.\n'
//             'The setState() method on $this was called with a closure or method that '
//             'returned a Future. Maybe it is marked as "async".\n'
//             'Instead of performing asynchronous work inside a call to setState(), first '
//             'execute the work (without updating the widget state), and then synchronously '
//             'update the state inside a call to setState().');
//       }
//       // We ignore other types of return values so that you can do things like:
//       //   setState(() => x = 3);
//       return true;
//     }());
//     _element.markNeedsBuild();
//   }
// }

// // TODO: take errors from StatefulElement
// class HookElement extends StatelessElement implements HookContext {
//   int _hooksIndex;
//   List<HookState> _hooks;

//   bool _debugIsBuilding;

//   HookElement(HookWidget widget) : super(widget);

//   @override
//   HookWidget get widget => super.widget as HookWidget;

//   @override
//   void performRebuild() {
//     _hooksIndex = 0;
//     assert(() {
//       _debugIsBuilding = true;
//       return true;
//     }());
//     super.performRebuild();
//     assert(() {
//       _debugIsBuilding = false;
//       return true;
//     }());
//   }

//   @override
//   void unmount() {
//     super.unmount();
//     if (_hooks != null) {
//       for (final hook in _hooks) {
//         try {
//           hook.dispose();
//         } catch (exception, stack) {
//           FlutterError.reportError(FlutterErrorDetails(
//             exception: exception,
//             stack: stack,
//             library: 'hooks library',
//             context: 'while disposing $runtimeType',
//           ));
//         }
//       }
//     }
//   }

//   @override
//   R use<R>(Hook<R> hook) {
//     assert(_debugIsBuilding == true, '''
//     Hooks should only be called within the build method of a widget.
//     Calling them outside of build method leads to an unstable state and is therefore prohibited
//     ''');

//     final hooksIndex = _hooksIndex;
//     _hooksIndex++;
//     _hooks ??= [];

//     HookState<R, Hook<R>> state;
//     if (hooksIndex >= _hooks.length) {
//       state = hook.createState()
//         .._element = this
//         .._hook = hook
//         ..initHook();
//       _hooks.add(state);
//     } else {
//       state = _hooks[hooksIndex] as HookState<R, Hook<R>>;
//       if (!identical(state._hook, hook)) {
//         // TODO: compare type for potential reassemble
//         final Hook previousHook = state._hook;
//         state
//           .._hook = hook
//           ..didUpdateHook(previousHook);
//       }
//     }
//     return state.build(this);
//   }

//   // AsyncSnapshot<T> useStream<T>(Stream<T> stream, {T initialData}) {
//   //   return use(_StreamHook<T>(stream: stream, initialData: initialData));
//   // }

//   // @override
//   // ValueNotifier<T> useState<T>({T initialData, void dispose(T value)}) {
//   //   return use(_StateHook(initialData: initialData, dispose: dispose));
//   // }

//   // @override
//   // T useAnimation<T>(Animation<T> animation) {
//   //   return use(_AnimationHook(animation));
//   // }

//   // @override
//   // AnimationController useAnimationController({Duration duration}) {
//   //   return use(_AnimationControllerHook(duration: duration));
//   // }

//   // @override
//   // TickerProvider useTickerProvider() {
//   //   return use(const _TickerProviderHook());
//   // }

//   // @override
//   // void useListenable(Listenable listenable) {
//   //   throw UnimplementedError();
//   // }

//   // @override
//   // T useMemoized<T>(T Function() valueBuilder,
//   //     {List parameters = const [], void dispose(T value)}) {
//   //   return use(_MemoizedHook(
//   //     valueBuilder,
//   //     dispose: dispose,
//   //     parameters: parameters,
//   //   ));
//   // }

//   // @override
//   // R useValueChanged<T, R>(T value, R valueChange(T oldValue, R oldResult)) {
//   //   return use(_ValueChangedHook(value, valueChange));
//   // }
// }

// abstract class StatelessHook<R> extends Hook<R> {
//   const StatelessHook();

//   R build(HookContext context);

//   @override
//   _StatelessHookState<R> createState() => _StatelessHookState<R>();
// }

// class _StatelessHookState<R> extends HookState<R, StatelessHook<R>> {
//   @override
//   R build(HookContext context) {
//     return hook.build(context);
//   }
// }

// abstract class HookWidget extends StatelessWidget {
//   const HookWidget({Key key}) : super(key: key);

//   @override
//   HookElement createElement() => HookElement(this);

//   @protected
//   @override
//   Widget build(covariant HookContext context);
// }

// abstract class HookContext extends BuildContext {
//   R use<R>(Hook<R> hook);

//   // ValueNotifier<T> useState<T>({T initialData, void dispose(T value)});
//   // T useMemoized<T>(T valueBuilder(), {List parameters, void dispose(T value)});
//   // R useValueChanged<T, R>(T value, R valueChange(T oldValue, R oldResult));
//   // // void useListenable(Listenable listenable);
//   // void useListenable(Listenable listenable);
//   // T useAnimation<T>(Animation<T> animation);
//   // // T useValueListenable<T>(ValueListenable<T> valueListenable);
//   // // AsyncSnapshot<T> useStream<T>(Stream<T> stream, {T initialData});
//   // AnimationController useAnimationController({Duration duration});
//   // TickerProvider useTickerProvider();
// }
