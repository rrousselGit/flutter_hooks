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
  int _debugHooksIndex;
  List<HookState> _hooks;

  bool _debugIsBuilding;
  bool _didReassemble;
  bool _isFirstBuild;

  /// Creates an element that uses the given widget as its configuration.
  HookElement(HookWidget widget) : super(widget);

  @override
  HookWidget get widget => super.widget as HookWidget;

  @override
  void performRebuild() {
    _currentHook = _hooks?.iterator;
    // first iterator always has null
    _currentHook?.moveNext();
    assert(() {
      _debugHooksIndex = 0;
      _isFirstBuild ??= true;
      _didReassemble ??= false;
      _debugIsBuilding = true;
      return true;
    }());
    super.performRebuild();
    assert(_debugHooksIndex == (_hooks?.length ?? 0), '''
Build for $widget finished with less hooks used than a previous build.

This may happen if the call to `use` is made under some condition.
Remove that condition to fix this error.
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
      // TODO: test
      assert(() {
        if (!_didReassemble) {
          return true;
        }
        if (_currentHook.current?.hook?.runtimeType == hook.runtimeType) {
          return true;
        } else if (_currentHook.current != null) {
          for (var i = _hooks.length - 1; i >= _debugHooksIndex; i--) {
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
        final previousHook = hookState._hook;
        hookState
          .._hook = hook
          ..didUpdateHook(previousHook);
      }
    }
    assert(() {
      _debugHooksIndex++;
      return true;
    }());
    return hookState.build(this);
  }

  HookState<R, Hook<R>> _createHookState<R>(Hook<R> hook) {
    return hook.createState()
      .._element = state
      .._hook = hook
      ..initHook();
  }

  @override
  ValueNotifier<T> useState<T>({T initialData}) {
    return use(_StateHook(initialData: initialData));
  }

  @override
  T useMemoized<T>(T Function() valueBuilder, {List parameters = const []}) {
    return use(_MemoizedHook(
      valueBuilder,
      parameters: parameters,
    ));
  }

  @override
  R useValueChanged<T, R>(T value, R valueChange(T oldValue, R oldResult)) {
    return use(_ValueChangedHook(value, valueChange));
  }
}

/// A [Widget] that can use [Hook]
///
/// It's usage is very similar to [StatelessWidget]:
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

  /// Create a mutable value and subscribes to it.
  ///
  /// Whenever [ValueNotifier.value] updates, it will mark the caller [HookContext]
  /// as needing build.
  /// On first call, inits [ValueNotifier] to [initialData]. [initialData] is ignored
  /// on subsequent calls.
  ///
  /// See also:
  ///
  ///  * [use]
  ///  * [Hook]
  ValueNotifier<T> useState<T>({T initialData});

  /// Create and cache the instance of an object.
  ///
  /// [useMemoized] will immediatly call [valueBuilder] on first call and store its result.
  /// Later calls to [useMemoized] will reuse the created instance.
  ///
  ///  * [parameters] can be use to specify a list of objects for [useMemoized] to watch.
  /// So that whenever [operator==] fails on any parameter or if the length of [parameters] changes,
  /// [valueBuilder] is called again.
  T useMemoized<T>(T valueBuilder(), {List parameters});

  /// Watches a value.
  ///
  /// Whenever [useValueChanged] is called with a diffent [value], calls [valueChange].
  /// The value returned by [useValueChanged] is the latest returned value of [valueChange] or `null`.
  R useValueChanged<T, R>(T value, R valueChange(T oldValue, R oldResult));
}
