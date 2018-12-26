part of 'hook.dart';

/// [Hook] is similar to a [StatelessWidget], but is not associated
/// to an [Element].
///
/// A [Hook] is typically the equivalent of [State] for [StatefulWidget],
/// with the notable difference that a [HookWidget] can have more than one [Hook].
/// A [Hook] is created within the [HookState.build] method of [HookWidget] and the creation
/// must be made unconditionally, always in the same order.
///
/// ### Good:
/// ```
/// class Good extends HookWidget {
///   @override
///   Widget build(HookContext context) {
///     final name = context.useState("");
///     // ...
///   }
/// }
/// ```
///
/// ### Bad:
/// ```
/// class Bad extends HookWidget {
///   @override
///   Widget build(HookContext context) {
///     if (condition) {
///       final name = context.useState("");
///       // ...
///     }
///   }
/// }
/// ```
///
/// The reason for such restriction is that [HookState] are obtained based on their index.
/// So the index must never ever change, or it will lead to undesired behavior.
///
/// ## The usage
///
/// [Hook] is powerful tool to reuse [State] logic between multiple [Widget].
/// They are used to extract logic that depends on a [Widget] life-cycle (such as [HookState.dispose]).
///
/// While mixins are a good candidate too, they do not allow sharing values. A mixin cannot reasonnably
/// define a variable, as this can lead to variable conflicts on bigger widgets.
///
/// Hooks are designed so that they get the benefits of mixins, but are totally independent from each others.
/// This means that hooks can store and expose values without fearing that the name is already taken by another mixin.
///
/// ## Example
///
/// A common use-case is to handle disposable objects such as [AnimationController].
///
/// With the usual [StatefulWidget], we would typically have the following:
///
/// ```
/// class Usual extends StatefulWidget {
///   @override
///   _UsualState createState() => _UsualState();
/// }
///
/// class _UsualState extends State<Usual>
///     with SingleTickerProviderStateMixin {
///   AnimationController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = AnimationController(
///       vsync: this,
///       duration: const Duration(seconds: 1),
///     );
///   }
///
///   @override
///   void dispose() {
///     super.dispose();
///     _controller.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Container(
///
///     );
///   }
/// }
/// ```
///
/// This is undesired because every single widget that want to use an [AnimationController] will have to
/// rewrite this extact piece of code.
///
/// With hooks it is possible to extract that exact piece of code into a reusable one.
///
/// This means that with [HookWidget] the following code is equivalent to the previous example:
///
/// ```
/// class Usual extends HookWidget {
///   @override
///   Widget build(HookContext context) {
///     final animationController =
///         context.useAnimationController(duration: const Duration(seconds: 1));
///     return Container();
///   }
/// }
/// ```
///
/// This is visibly less code then before. But in this example, the `animationController` is still
/// guaranted to be disposed when the widget is removed from the tree.
///
/// In fact this has secondary bonus: `duration` is kept updated with the latest value.
/// If we were to pass a variable as `duration` instead of a constant, then on value change the [AnimationController] will be updated.
@immutable
abstract class Hook<R> {
  /// Allows subclasses to have a `const` constructor
  const Hook({this.keys});

  /// A list of objects that specify if a [HookState] should be reused or a new one should be created.
  ///
  /// When a new [Hook] is created, the framework checks if keys matches using [Hook.shouldPreserveState].
  /// If they don't, the previously created [HookState] is disposed, and a new one is created
  /// using [Hook.createState], followed by [HookState.initHook].
  final List keys;

  /// The algorithm to determine if a [HookState] should be reused or disposed.
  ///
  /// This compares [Hook.keys] to see if they contains any difference.
  /// A state is preserved when:
  ///
  /// - `hook1.keys == hook2.keys` (typically if the list is immutable)
  /// - If there's any difference in the content of [Hook.keys], using `operator==`.
  static bool shouldPreserveState(Hook hook1, Hook hook2) {
    final p1 = hook1.keys;
    final p2 = hook2.keys;

    if (p1 == p2) {
      return true;
    }
    // is one list is null and the other one isn't, or if they have different size
    if ((p1 != p2 && (p1 == null || p2 == null)) || p1.length != p2.length) {
      return false;
    }

    var i1 = p1.iterator;
    var i2 = p2.iterator;
    while (true) {
      if (!i1.moveNext() || !i2.moveNext()) {
        return true;
      }
      if (i1.current != i2.current) {
        return false;
      }
    }
  }

  /// Creates the mutable state for this hook linked to its widget creator.
  ///
  /// Subclasses should override this method to return a newly created instance of their associated State subclass:
  ///
  /// ```
  /// @override
  /// HookState createState() => _MyHookState();
  /// ```
  ///
  /// The framework can call this method multiple times over the lifetime of a [HookWidget]. For example,
  /// if the hook is used multiple times, a separate [HookState] must be created for each usage.
  @protected
  HookState<R, Hook<R>> createState();
}

/// The logic and internal state for a [HookWidget]
abstract class HookState<R, T extends Hook<R>> {
  /// Equivalent of [State.context] for [HookState]
  @protected
  BuildContext get context => _element.context;
  State _element;

  /// Equivalent of [State.widget] for [HookState]
  T get hook => _hook;
  T _hook;

  /// Equivalent of [State.initState] for [HookState]
  @protected
  @mustCallSuper
  void initHook() {}

  /// Equivalent of [State.dispose] for [HookState]
  @protected
  @mustCallSuper
  void dispose() {}

  /// Called everytimes the [HookState] is requested
  ///
  /// [build] is where an [HookState] may use other hooks. This restriction is made to ensure that hooks are unconditionally always requested
  @protected
  R build(HookContext context);

  /// Equivalent of [State.didUpdateWidget] for [HookState]
  @protected
  @mustCallSuper
  void didUpdateHook(covariant Hook<R> oldHook) {}

  /// Equivalent of [State.setState] for [HookState]
  @protected
  void setState(VoidCallback fn) {
    // ignore: invalid_use_of_protected_member
    _element.setState(fn);
  }
}

/// An [Element] that uses a [HookWidget] as its configuration.
class HookElement extends StatefulElement implements HookContext {
  Iterator<HookState> _currentHook;
  int _hookIndex;
  List<HookState> _hooks;

  bool _debugIsBuilding;
  bool _didReassemble;
  bool _isFirstBuild;
  bool _debugShouldDispose;

  /// Creates an element that uses the given widget as its configuration.
  HookElement(HookWidget widget) : super(widget);

  @override
  HookWidget get widget => super.widget as HookWidget;

  @override
  void performRebuild() {
    _currentHook = _hooks?.iterator;
    // first iterator always has null
    _currentHook?.moveNext();
    _hookIndex = 0;
    assert(() {
      _debugShouldDispose = false;
      _isFirstBuild ??= true;
      _didReassemble ??= false;
      _debugIsBuilding = true;
      return true;
    }());
    super.performRebuild();

    // dispose removed items
    assert(() {
      if (_didReassemble) {
        // TODO: test for the _currentHook == null
        while (_currentHook?.current != null) {
          _currentHook.current.dispose();
          _currentHook.moveNext();
          _hookIndex++;
        }
      }
      return true;
    }());
    assert(_hookIndex == (_hooks?.length ?? 0), '''
Build for $widget finished with less hooks used than a previous build.
Used $_hookIndex hooks while a previous build had ${_hooks.length}.
This may happen if the call to `use` is made under some condition.

''');
    assert(() {
      _isFirstBuild = false;
      _didReassemble = false;
      _debugIsBuilding = false;
      return true;
    }());
  }

  @override
  void unmount() {
    super.unmount();
    if (_hooks != null) {
      for (final hook in _hooks) {
        try {
          hook.dispose();
        } catch (exception, stack) {
          FlutterError.reportError(FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'hooks library',
            context: 'while disposing ${hook.runtimeType}',
          ));
        }
      }
    }
  }

  @override
  R use<R>(Hook<R> hook) {
    assert(_debugIsBuilding == true, '''
    Hooks should only be called within the build method of a widget.
    Calling them outside of build method leads to an unstable state and is therefore prohibited
    ''');

    HookState<R, Hook<R>> hookState;
    // first build
    if (_currentHook == null) {
      assert(_didReassemble || _isFirstBuild);
      hookState = _createHookState(hook);
      _hooks ??= [];
      _hooks.add(hookState);
    } else {
      // recreate states on hot-reload of the order changed
      assert(() {
        if (!_didReassemble) {
          return true;
        }
        if (!_debugShouldDispose &&
            _currentHook.current?.hook?.runtimeType == hook.runtimeType) {
          return true;
        }
        _debugShouldDispose = true;

        // some previous hook has changed of type, so we dispose all the following states
        // _currentHook.current can be null when reassemble is adding new hooks
        if (_currentHook.current != null) {
          _hooks.remove(_currentHook.current..dispose());
          // has to be done after the dispose call
          hookState = _createHookState(hook);
          _hooks.insert(_hookIndex, hookState);

          // we move the iterator back to where it was
          _currentHook = _hooks.iterator..moveNext();
          for (var i = 0; i < _hooks.length && _hooks[i] != hookState; i++) {
            _currentHook.moveNext();
          }
        } else {
          // new hooks have been pushed at the end of the list.
          hookState = _createHookState(hook);
          _hooks.add(hookState);

          // we put the iterator on added item
          _currentHook = _hooks.iterator;
          while (_currentHook.current != hookState) {
            _currentHook.moveNext();
          }
        }
        return true;
      }());
      assert(_currentHook.current?.hook?.runtimeType == hook.runtimeType);

      if (_currentHook.current.hook == hook) {
        hookState = _currentHook.current as HookState<R, Hook<R>>;
        _currentHook.moveNext();
      } else if (Hook.shouldPreserveState(_currentHook.current.hook, hook)) {
        hookState = _currentHook.current as HookState<R, Hook<R>>;
        _currentHook.moveNext();
        final previousHook = hookState._hook;
        hookState
          .._hook = hook
          ..didUpdateHook(previousHook);
      } else {
        _hooks.removeAt(_hookIndex).dispose();
        hookState = _createHookState(hook);
        _hooks.insert(_hookIndex, hookState);

        // we move the iterator back to where it was
        _currentHook = _hooks.iterator..moveNext();
        for (var i = 0; i < _hooks.length && _hooks[i] != hookState; i++) {
          _currentHook.moveNext();
        }
        _currentHook.moveNext();
      }
    }
    _hookIndex++;
    return hookState.build(this);
  }

  HookState<R, Hook<R>> _createHookState<R>(Hook<R> hook) {
    return hook.createState()
      .._element = state
      .._hook = hook
      ..initHook();
  }

  @override
  R useValueChanged<T, R>(T value, R valueChange(T oldValue, R oldResult)) {
    return use(_ValueChangedHook(value, valueChange));
  }

  @override
  AnimationController useAnimationController({
    Duration duration,
    String debugLabel,
    double initialValue = 0,
    double lowerBound = 0,
    double upperBound = 1,
    TickerProvider vsync,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
    List keys,
  }) {
    return use(_AnimationControllerHook(
      duration: duration,
      debugLabel: debugLabel,
      initialValue: initialValue,
      lowerBound: lowerBound,
      upperBound: upperBound,
      vsync: vsync,
      animationBehavior: animationBehavior,
      keys: keys,
    ));
  }

  @override
  void useListenable(Listenable listenable) {
    use(_ListenableHook(listenable));
  }

  @override
  T useAnimation<T>(Animation<T> animation) {
    useListenable(animation);
    return animation.value;
  }

  @override
  T useValueListenable<T>(ValueListenable<T> valueListenable) {
    useListenable(valueListenable);
    return valueListenable.value;
  }

  @override
  AsyncSnapshot<T> useStream<T>(Stream<T> stream, {T initialData}) {
    return use(_StreamHook(stream, initialData: initialData));
  }

  @override
  AsyncSnapshot<T> useFuture<T>(Future<T> future, {T initialData}) {
    return use(_FutureHook(future, initialData: initialData));
  }

  @override
  TickerProvider useSingleTickerProvider({List keys}) {
    return use(
      keys != null ? _TickerProviderHook(keys) : const _TickerProviderHook(),
    );
  }

  @override
  void useEffect(VoidCallback Function() effect, [List keys]) {
    use(_EffectHook(effect, keys));
  }

  @override
  T useMemoized<T>(T Function() valueBuilder, [List keys = const []]) {
    return use(_MemoizedHook(
      valueBuilder,
      keys: keys,
    ));
  }

  @override
  ValueNotifier<T> useState<T>([T initialData]) {
    return use(_StateHook(initialData: initialData));
  }

  @override
  StreamController<T> useStreamController<T>(
      {bool sync = false,
      VoidCallback onListen,
      VoidCallback onCancel,
      List keys}) {
    return use(_StreamControllerHook(
      onCancel: onCancel,
      onListen: onListen,
      sync: sync,
      keys: keys,
    ));
  }
}

/// A [Widget] that can use [Hook]
///
/// It's usage is very similar to [StatelessWidget].
/// [HookWidget] do not have any life-cycle and implements
/// only a [build] method.
///
/// The difference is that it can use [Hook], which allows
/// [HookWidget] to store mutable data without implementing a [State].
abstract class HookWidget extends StatefulWidget {
  /// Initializes [key] for subclasses.
  const HookWidget({Key key}) : super(key: key);

  @override
  HookElement createElement() => HookElement(this);

  @override
  _HookWidgetState createState() => _HookWidgetState();

  /// Describes the part of the user interface represented by this widget.
  ///
  /// See also:
  ///
  ///  * [StatelessWidget.build]
  @protected
  Widget build(covariant HookContext context);
}

class _HookWidgetState extends State<HookWidget> {
  @override
  void reassemble() {
    super.reassemble();
    assert(() {
      (context as HookElement)._didReassemble = true;
      return true;
    }());
  }

  @override
  Widget build(covariant HookContext context) {
    return widget.build(context);
  }
}

/// A [HookWidget] that defer its [HookWidget.build] to a callback
class HookBuilder extends HookWidget {
  /// The callback used by [HookBuilder] to create a widget.
  ///
  /// If the passed [HookContext] trigger a rebuild, [builder] will be called again.
  /// [builder] must not return `null`.
  final Widget Function(HookContext context) builder;

  /// Creates a widget that delegates its build to a callback.
  ///
  /// The [builder] argument must not be null.
  const HookBuilder({
    @required this.builder,
    Key key,
  })  : assert(builder != null),
        super(key: key);

  @override
  Widget build(HookContext context) => builder(context);
}

/// A [BuildContext] that can use a [Hook].
///
/// See also:
///
///  * [BuildContext]
abstract class HookContext extends BuildContext {
  /// Register a [Hook] and returns its value
  ///
  /// [use] must be called withing [HookWidget.build] and
  /// all calls to [use] must be made unconditionally, always
  /// on the same order.
  ///
  /// See [Hook] for more explanations.
  R use<R>(Hook<R> hook);

  /// A hook for side-effects
  ///
  /// [useEffect] is called synchronously on every [HookWidget.build], unless
  /// [parameters] is specified. In which case [useEffect] is called again only if
  /// any value inside [parameters] as changed.
  void useEffect(VoidCallback effect(), [List parameters]);

  /// Create  value and subscribes to it.
  ///
  /// Whenever [ValueNotifier.value] updates, it will mark the caller [HookContext]
  /// as needing build.
  /// On first call, inits [ValueNotifier] to [initialData]. [initialData] is ignored
  /// on subsequent calls.
  ///
  /// See also:
  ///
  ///  * [ValueNotifier]
  ///  * [useStreamController], an alternative to [ValueNotifier] for state.
  ValueNotifier<T> useState<T>([T initialData]);

  /// Create and cache the instance of an object.
  ///
  /// [useMemoized] will immediatly call [valueBuilder] on first call and store its result.
  /// Later calls to [useMemoized] will reuse the created instance.
  ///
  ///  * [keys] can be use to specify a list of objects for [useMemoized] to watch.
  /// So that whenever [operator==] fails on any parameter or if the length of [keys] changes,
  /// [valueBuilder] is called again.
  T useMemoized<T>(T valueBuilder(), [List keys = const []]);

  /// Watches a value.
  ///
  /// Whenever [useValueChanged] is called with a diffent [value], calls [valueChange].
  /// The value returned by [useValueChanged] is the latest returned value of [valueChange] or `null`.
  R useValueChanged<T, R>(T value, R valueChange(T oldValue, R oldResult));

  /// Creates a single usage [TickerProvider].
  ///
  /// See also:
  ///  * [SingleTickerProviderStateMixin]
  TickerProvider useSingleTickerProvider({List keys});

  /// Creates an [AnimationController] automatically disposed.
  ///
  /// If no [vsync] is provided, the [TickerProvider] is implicitly obtained using [useSingleTickerProvider].
  /// If a [vsync] is specified, changing the instance of [vsync] will result in a call to [AnimationController.resync].
  /// It is not possible to switch between implicit and explicit [vsync].
  ///
  /// Changing the [duration] parameter automatically updates [AnimationController.duration].
  ///
  /// [initialValue], [lowerBound], [upperBound] and [debugLabel] are ignored after the first call.
  ///
  /// See also:
  ///   * [AnimationController]
  ///   * [HookContext.useAnimation]
  AnimationController useAnimationController({
    Duration duration,
    String debugLabel,
    double initialValue = 0,
    double lowerBound = 0,
    double upperBound = 1,
    TickerProvider vsync,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
    List keys,
  });

  /// Creates a [StreamController] automatically disposed.
  ///
  /// See also:
  ///   * [StreamController]
  ///   * [HookContext.useStream]
  StreamController<T> useStreamController<T>({
    bool sync = false,
    VoidCallback onListen,
    VoidCallback onCancel,
    List keys,
  });

  /// Subscribes to a [Listenable] and mark the widget as needing build
  /// whenever the listener is called.
  ///
  /// See also:
  ///   * [Listenable]
  ///   * [HookContext.useValueListenable], [HookContext.useAnimation], [HookContext.useStream]
  void useListenable(Listenable listenable);

  /// Subscribes to a [ValueListenable] and return its value.
  ///
  /// See also:
  ///   * [ValueListenable]
  ///   * [HookContext.useListenable], [HookContext.useAnimation], [HookContext.useStream]
  T useValueListenable<T>(ValueListenable<T> valueListenable);

  /// Subscribes to an [Animation] and return its value.
  ///
  /// See also:
  ///   * [Animation]
  ///   * [HookContext.useValueListenable], [HookContext.useListenable], [HookContext.useStream]
  T useAnimation<T>(Animation<T> animation);

  /// Subscribes to a [Stream] and return its current state in an [AsyncSnapshot].
  ///
  /// See also:
  ///   * [Stream]
  ///   * [HookContext.useValueListenable], [HookContext.useListenable], [HookContext.useAnimation]
  AsyncSnapshot<T> useStream<T>(Stream<T> stream, {T initialData});

  /// Subscribes to a [Future] and return its current state in an [AsyncSnapshot].
  ///
  /// See also:
  ///   * [Future]
  ///   * [HookContext.useValueListenable], [HookContext.useListenable], [HookContext.useAnimation]
  AsyncSnapshot<T> useFuture<T>(Future<T> future, {T initialData});
}
