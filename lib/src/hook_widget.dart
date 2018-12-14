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
/// With hooks it is possible to extract that exact piece of code into a reusable one. In fact, one is already provided by default:
/// [HookContext.useAnimationController]
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
  const Hook();

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

/// Tracks the lifecycle of [State] objects when asserts are enabled.
enum _HookLifecycle {
  /// The [State] object has been created. [State.initState] is called at this
  /// time.
  created,

  /// The [State.initState] method has been called but the [State] object is
  /// not yet ready to build. [State.didChangeDependencies] is called at this time.
  initialized,

  /// The [State] object is ready to build and [State.dispose] has not yet been
  /// called.
  ready,

  /// The [State.dispose] method has been called and the [State] object is
  /// no longer able to build.
  defunct,
}

/// The logic and internal state for a [HookWidget]
///
/// A [HookState]
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
  void initHook() {}

  /// Equivalent of [State.dispose] for [HookState]
  @protected
  void dispose() {}

  /// Called everytimes the [HookState] is requested
  ///
  /// [build] is where an [HookState] may use other hooks. This restriction is made to ensure that hooks are unconditionally always requested
  @protected
  R build(HookContext context);

  /// Equivalent of [State.didUpdateWidget] for [HookState]
  @protected
  void didUpdateHook(covariant Hook oldHook) {}

  /// Equivalent of [State.setState] for [HookState]
  @protected
  void setState(VoidCallback fn) {
    // ignore:  invalid_use_of_protected_member
    _element.setState(fn);
  }
}

class HookElement extends StatefulElement implements HookContext {
  Iterator<HookState> _currentHook;
  int _hooksIndex;
  List<HookState> _hooks;

  bool _debugIsBuilding;
  bool _didReassemble;
  bool _isFirstBuild;

  HookElement(HookWidget widget) : super(widget);

  @override
  HookWidget get widget => super.widget as HookWidget;

  @override
  void performRebuild() {
    _currentHook = _hooks?.iterator;
    // first iterator always has null for unknown reasons
    _currentHook?.moveNext();
    _hooksIndex = 0;
    assert(() {
      _isFirstBuild ??= true;
      _didReassemble ??= false;
      _debugIsBuilding = true;
      return true;
    }());
    super.performRebuild();
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
        if (_currentHook.current?.hook?.runtimeType == hook.runtimeType) {
          return true;
        } else if (_currentHook.current != null) {
          for (var i = _hooks.length - 1; i >= _hooksIndex; i--) {
            _hooks.removeLast().dispose();
          }
        }
        hookState = _createHookState(hook);
        _hooks.add(hookState);
        _currentHook = _hooks.iterator;
        for (var i = 0; i < _hooks.length; i++) {
          _currentHook.moveNext();
        }

        return true;
      }());
      assert(_currentHook.current.hook.runtimeType == hook.runtimeType);

      hookState = _currentHook.current as HookState<R, Hook<R>>;
      _currentHook.moveNext();

      if (hookState._hook != hook) {
        // TODO: compare type for potential reassemble
        final Hook previousHook = hookState._hook;
        hookState
          .._hook = hook
          ..didUpdateHook(previousHook);
      }
    }

    _hooksIndex++;
    return hookState.build(this);
  }

  HookState<R, Hook<R>> _createHookState<R>(Hook<R> hook) {
    return hook.createState()
      .._element = state
      .._hook = hook
      ..initHook();
  }

  AsyncSnapshot<T> useStream<T>(Stream<T> stream, {T initialData}) {
    return use(_StreamHook<T>(stream: stream, initialData: initialData));
  }

  @override
  ValueNotifier<T> useState<T>({T initialData, void dispose(T value)}) {
    return use(_StateHook(initialData: initialData, dispose: dispose));
  }

  @override
  T useAnimation<T>(Animation<T> animation) {
    return use(_AnimationHook(animation));
  }

  @override
  AnimationController useAnimationController({Duration duration}) {
    return use(_AnimationControllerHook(duration: duration));
  }

  @override
  TickerProvider useTickerProvider() {
    return use(const _TickerProviderHook());
  }

  @override
  void useListenable(Listenable listenable) {
    throw UnimplementedError();
  }

  @override
  T useMemoized<T>(T Function() valueBuilder,
      {List parameters = const [], void dispose(T value)}) {
    return use(_MemoizedHook(
      valueBuilder,
      dispose: dispose,
      parameters: parameters,
    ));
  }

  @override
  R useValueChanged<T, R>(T value, R valueChange(T oldValue, R oldResult)) {
    return use(_ValueChangedHook(value, valueChange));
  }
}

abstract class StatelessHook<R> extends Hook<R> {
  const StatelessHook();

  R build(HookContext context);

  @override
  _StatelessHookState<R> createState() => _StatelessHookState<R>();
}

class _StatelessHookState<R> extends HookState<R, StatelessHook<R>> {
  @override
  R build(HookContext context) {
    return hook.build(context);
  }
}

abstract class HookWidget extends StatefulWidget {
  const HookWidget({Key key}) : super(key: key);

  @override
  HookElement createElement() => HookElement(this);

  @override
  _HookWidgetState createState() => _HookWidgetState();

  @protected
  @override
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

abstract class HookContext extends BuildContext {
  R use<R>(Hook<R> hook);

  ValueNotifier<T> useState<T>({T initialData, void dispose(T value)});
  T useMemoized<T>(T valueBuilder(), {List parameters, void dispose(T value)});
  R useValueChanged<T, R>(T value, R valueChange(T oldValue, R oldResult));
  // void useListenable(Listenable listenable);
  void useListenable(Listenable listenable);
  T useAnimation<T>(Animation<T> animation);
  // T useValueListenable<T>(ValueListenable<T> valueListenable);
  // AsyncSnapshot<T> useStream<T>(Stream<T> stream, {T initialData});
  AnimationController useAnimationController({Duration duration});
  TickerProvider useTickerProvider();
}
