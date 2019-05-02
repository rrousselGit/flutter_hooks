import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Wether to behave like in release mode or allow hot-reload for hooks.
///
/// `true` by default. It has no impact on release builds.
bool debugHotReloadHooksEnabled = true;

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
///   Widget build(BuildContext context) {
///     final name = useState("");
///     // ...
///   }
/// }
/// ```
///
/// ### Bad:
/// ```
/// class Bad extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     if (condition) {
///       final name = useState("");
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
///     _controller.dispose();
///     super.dispose();
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
///   Widget build(BuildContext context) {
///     final animationController = useAnimationController(duration: const Duration(seconds: 1));
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

  /// Register a [Hook] and returns its value
  ///
  /// [use] must be called withing [HookWidget.build] and
  /// all calls to [use] must be made unconditionally, always
  /// on the same order.
  ///
  /// See [Hook] for more explanations.
  static R use<R>(Hook<R> hook) {
    assert(HookElement._currentContext != null, '''
`Hook.use` can only be called from the build method of HookWidget.
Hooks should only be called within the build method of a widget.
Calling them outside of build method leads to an unstable state and is therefore prohibited.
''');
    return HookElement._currentContext._use(hook);
  }

  /// A list of objects that specify if a [HookState] should be reused or a new one should be created.
  ///
  /// When a new [Hook] is created, the framework checks if keys matches using [Hook.shouldPreserveState].
  /// If they don't, the previously created [HookState] is disposed, and a new one is created
  /// using [Hook.createState], followed by [HookState.initHook].
  final List<Object> keys;

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
  void initHook() {}

  /// Equivalent of [State.dispose] for [HookState]
  @protected
  void dispose() {}

  /// Called synchronously after the [HookWidget.build] method finished
  @protected
  void didBuild() {}

  /// Called everytimes the [HookState] is requested
  ///
  /// [build] is where an [HookState] may use other hooks. This restriction is made to ensure that hooks are unconditionally always requested
  @protected
  R build(BuildContext context);

  /// Equivalent of [State.didUpdateWidget] for [HookState]
  @protected
  void didUpdateHook(T oldHook) {}

  /// {@macro flutter.widgets.reassemble}
  ///
  /// In addition to this method being invoked, it is guaranteed that the
  /// [build] method will be invoked when a reassemble is signaled. Most
  /// widgets therefore do not need to do anything in the [reassemble] method.
  ///
  /// See also:
  ///
  ///  * [State.reassemble]
  void reassemble() {}

  /// Equivalent of [State.setState] for [HookState]
  @protected
  void setState(VoidCallback fn) {
    // ignore: invalid_use_of_protected_member
    _element.setState(fn);
  }
}

/// An [Element] that uses a [HookWidget] as its configuration.
class HookElement extends StatefulElement {
  static HookElement _currentContext;

  /// Creates an element that uses the given widget as its configuration.
  HookElement(HookWidget widget) : super(widget);

  Iterator<HookState> _currentHook;
  int _hookIndex;
  List<HookState> _hooks;
  bool _didFinishBuildOnce = false;

  bool _debugDidReassemble;
  bool _debugShouldDispose;
  bool _debugIsInitHook;

  @override
  HookWidget get widget => super.widget as HookWidget;

  @override
  Widget build() {
    _currentHook = _hooks?.iterator;
    // first iterator always has null
    _currentHook?.moveNext();
    _hookIndex = 0;
    assert(() {
      _debugShouldDispose = false;
      _debugIsInitHook = false;
      _debugDidReassemble ??= false;
      return true;
    }());
    HookElement._currentContext = this;
    final result = super.build();
    HookElement._currentContext = null;

    // dispose removed items
    assert(() {
      if (!debugHotReloadHooksEnabled) return true;
      if (_debugDidReassemble && _hooks != null) {
        for (var i = _hookIndex; i < _hooks.length;) {
          _hooks.removeAt(i).dispose();
        }
      }
      return true;
    }());
    assert(_hookIndex == (_hooks?.length ?? 0), '''
Build for $widget finished with less hooks used than a previous build.
Used $_hookIndex hooks while a previous build had ${_hooks.length}.
This may happen if the call to `Hook.use` is made under some condition.

''');
    assert(() {
      if (!debugHotReloadHooksEnabled) return true;
      _debugDidReassemble = false;
      return true;
    }());
    _didFinishBuildOnce = true;
    return result;
  }

  /// A read-only list of all hooks available.
  ///
  /// These should not be used directly and are exposed
  @visibleForTesting
  List<HookState> get debugHooks => List<HookState>.unmodifiable(_hooks);

  @override
  InheritedWidget inheritFromWidgetOfExactType(Type targetType,
      {Object aspect}) {
    assert(!_debugIsInitHook);
    return super.inheritFromWidgetOfExactType(targetType, aspect: aspect);
  }

  @override
  Element updateChild(Element child, Widget newWidget, dynamic newSlot) {
    if (_hooks != null) {
      for (final hook in _hooks.reversed) {
        try {
          hook.didBuild();
        } catch (exception, stack) {
          FlutterError.reportError(FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'hooks library',
            context: ErrorDescription(
                'while calling `didBuild` on ${hook.runtimeType}'),
          ));
        }
      }
    }
    return super.updateChild(child, newWidget, newSlot);
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
            context: ErrorDescription('while disposing ${hook.runtimeType}'),
          ));
        }
      }
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    assert(() {
      _debugDidReassemble = true;
      if (_hooks != null) {
        for (final hook in _hooks) {
          hook.reassemble();
        }
      }
      return true;
    }());
  }

  R _use<R>(Hook<R> hook) {
    HookState<R, Hook<R>> hookState;
    // first build
    if (_currentHook == null) {
      assert(_debugDidReassemble || !_didFinishBuildOnce);
      hookState = _createHookState(hook);
      _hooks ??= [];
      _hooks.add(hookState);
    } else {
      // recreate states on hot-reload of the order changed
      assert(() {
        if (!debugHotReloadHooksEnabled) return true;
        if (!_debugDidReassemble) {
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
          hookState = _insertHookAt(_hookIndex, hook);
        } else {
          hookState = _pushHook(hook);
        }
        return true;
      }());
      if (!_didFinishBuildOnce && _currentHook.current == null) {
        hookState = _pushHook(hook);
        _currentHook.moveNext();
      } else {
        assert(_currentHook.current != null);
        assert(_debugTypesAreRight(hook));

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
          hookState = _replaceHookAt(_hookIndex, hook);
          _resetsIterator(hookState);
          _currentHook.moveNext();
        }
      }
    }
    _hookIndex++;
    return hookState.build(this);
  }

  HookState<R, Hook<R>> _replaceHookAt<R>(int index, Hook<R> hook) {
    _hooks.removeAt(_hookIndex).dispose();
    var hookState = _createHookState(hook);
    _hooks.insert(_hookIndex, hookState);
    return hookState;
  }

  HookState<R, Hook<R>> _insertHookAt<R>(int index, Hook<R> hook) {
    var hookState = _createHookState(hook);
    _hooks.insert(index, hookState);
    _resetsIterator(hookState);
    return hookState;
  }

  HookState<R, Hook<R>> _pushHook<R>(Hook<R> hook) {
    var hookState = _createHookState(hook);
    _hooks.add(hookState);
    _resetsIterator(hookState);
    return hookState;
  }

  bool _debugTypesAreRight(Hook hook) {
    assert(_currentHook.current.hook.runtimeType == hook.runtimeType);
    return true;
  }

  /// we put the iterator on added item
  void _resetsIterator(HookState hookState) {
    _currentHook = _hooks.iterator;
    while (_currentHook.current != hookState) {
      _currentHook.moveNext();
    }
  }

  HookState<R, Hook<R>> _createHookState<R>(Hook<R> hook) {
    assert(() {
      _debugIsInitHook = true;
      return true;
    }());
    final state = hook.createState()
      .._element = this.state
      .._hook = hook
      ..initHook();

    assert(() {
      _debugIsInitHook = false;
      return true;
    }());

    return state;
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
  Widget build(BuildContext context);
}

class _HookWidgetState extends State<HookWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.build(context);
  }
}

/// Obtain the [BuildContext] of the building [HookWidget].
BuildContext useContext() {
  assert(HookElement._currentContext != null,
      '`useContext` can only be called from the build method of HookWidget');
  return HookElement._currentContext;
}

/// A [HookWidget] that defer its [HookWidget.build] to a callback
class HookBuilder extends HookWidget {
  /// The callback used by [HookBuilder] to create a widget.
  ///
  /// If a [Hook] asks for a rebuild, [builder] will be called again.
  /// [builder] must not return `null`.
  final Widget Function(BuildContext context) builder;

  /// Creates a widget that delegates its build to a callback.
  ///
  /// The [builder] argument must not be null.
  const HookBuilder({
    @required this.builder,
    Key key,
  })  : assert(builder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) => builder(context);
}
