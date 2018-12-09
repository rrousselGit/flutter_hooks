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
abstract class Hook {
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
  HookState createState();
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
abstract class HookState<T extends Hook> extends Diagnosticable {
  _HookLifecycle _debugLifecycleState = _HookLifecycle.created;

  /// Equivalent of [State.context] for [HookState]
  @protected
  BuildContext get context => _element;
  Element _element;

  /// Equivalent of [State.widget] for [HookState]
  T get hook => _hook;
  T _hook;

  /// Equivalent of [State.initState] for [HookState]
  @protected
  @mustCallSuper
  void initHook() {
    assert(_debugLifecycleState == _HookLifecycle.created);
  }

  /// Equivalent of [State.deactivate] for [HookState]
  @protected
  @mustCallSuper
  void deactivate() {}

  /// Equivalent of [State.dispose] for [HookState]
  @protected
  @mustCallSuper
  void dispose() {
    assert(_debugLifecycleState == _HookLifecycle.ready);
    assert(() {
      _debugLifecycleState = _HookLifecycle.defunct;
      return true;
    }());
  }

  /// Called everytimes the [HookState] is requested
  ///
  /// [build] is where an [HookState] may use other hooks. This restriction is made to ensure that hooks are unconditionally always requested
  @protected
  void build(HookContext context) {}

  /// Equivalent of [State.didUpdateWidget] for [HookState]
  @protected
  @mustCallSuper
  void didUpdateHook(covariant Hook oldHook) {}

  /// Equivalent of [State.setState] for [HookState]
  @protected
  void setState(VoidCallback fn) {
    assert(fn != null);
    assert(() {
      if (_debugLifecycleState == _HookLifecycle.defunct) {
        throw FlutterError('setState() called after dispose(): $this\n'
            'This error happens if you call setState() on a HookState object for a widget that '
            'no longer appears in the widget tree (e.g., whose parent widget no longer '
            'includes the widget in its build). This error can occur when code calls '
            'setState() from a timer or an animation callback. The preferred solution is '
            'to cancel the timer or stop listening to the animation in the dispose() '
            'callback. Another solution is to check the "mounted" property of this '
            'object before calling setState() to ensure the object is still in the '
            'tree.\n'
            'This error might indicate a memory leak if setState() is being called '
            'because another object is retaining a reference to this State object '
            'after it has been removed from the tree. To avoid memory leaks, '
            'consider breaking the reference to this object during dispose().');
      }
      if (_debugLifecycleState == _HookLifecycle.created && _element == null) {
        throw FlutterError('setState() called in constructor: $this\n'
            'This happens when you call setState() on a HookState object for a widget that '
            'hasn\'t been inserted into the widget tree yet. It is not necessary to call '
            'setState() in the constructor, since the state is already assumed to be dirty '
            'when it is initially created.');
      }
      return true;
    }());
    final result = fn() as dynamic;
    assert(() {
      if (result is Future) {
        throw FlutterError('setState() callback argument returned a Future.\n'
            'The setState() method on $this was called with a closure or method that '
            'returned a Future. Maybe it is marked as "async".\n'
            'Instead of performing asynchronous work inside a call to setState(), first '
            'execute the work (without updating the widget state), and then synchronously '
            'update the state inside a call to setState().');
      }
      // We ignore other types of return values so that you can do things like:
      //   setState(() => x = 3);
      return true;
    }());
    _element.markNeedsBuild();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    assert(() {
      properties.add(EnumProperty<_HookLifecycle>(
          'lifecycle state', _debugLifecycleState,
          defaultValue: _HookLifecycle.ready));
      return true;
    }());
    properties
      ..add(ObjectFlagProperty<T>('_hook', _hook, ifNull: 'no hook'))
      ..add(ObjectFlagProperty<Element>('_element', _element,
          ifNull: 'not mounted'));
  }
}

abstract class ValueHook<R> extends Hook {
  @override
  ValueHookState<R, ValueHook> createState();
}

abstract class ValueHookState<R, H extends ValueHook<R>> extends HookState<H> {
  @override
  R build(HookContext context);
}

class HookElement extends StatelessElement implements HookContext {
  int _hooksIndex;
  List<HookState> _hooks;

  bool _debugIsBuilding;

  HookElement(HookWidget widget) : super(widget);

  @override
  HookWidget get widget => super.widget as HookWidget;

  @override
  void performRebuild() {
    _hooksIndex = 0;
    assert(() {
      _debugIsBuilding = true;
      return true;
    }());
    super.performRebuild();
    assert(() {
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
            context: 'while disposing $runtimeType',
          ));
        }
      }
    }
  }

  @override
  HookState<T> useHook<T extends Hook>(T hook) {
    assert(_debugIsBuilding == true, '''
    Hooks should only be called within the build method of a widget.
    Calling them outside of build method leads to an unstable state and is therefore prohibited
    ''');

    final hooksIndex = _hooksIndex;
    _hooksIndex++;
    _hooks ??= [];

    HookState<T> state;
    if (hooksIndex >= _hooks.length) {
      state = hook.createState() as HookState<T>
        .._element = this
        .._hook = hook
        ..initHook();
      _hooks.add(state);
    } else {
      state = _hooks[hooksIndex] as HookState<T>;
      if (!identical(state._hook, hook)) {
        // TODO: compare type for potential reassemble
        final Hook previousHook = state._hook;
        state
          .._hook = hook
          ..didUpdateHook(previousHook);
      }
    }
    return state..build(this);
  }

  @override
  ValueNotifier<T> useState<T>({T initialData, void dispose(T value)}) {
    throw new UnimplementedError();
  }

  // @override
  // AsyncSnapshot<T> useStream<T>(Stream<T> stream, {T initialData}) {
  //   final _StreamHookState<T> state =
  //       useHook(_StreamHook<T>(stream: stream, initialData: initialData));
  //   return state.snapshot;
  // }

  @override
  T useAnimation<T>(Animation<T> animation) {
    throw new UnimplementedError();
  }

  // @override
  // void useListenable(Listenable listenable) {
  //   throw new UnimplementedError();
  // }

  // @override
  // T useValueListenable<T>(ValueListenable<T> valueListenable) {
  //   throw new UnimplementedError();
  // }

  @override
  AnimationController useAnimationController({Duration duration}) {
    final _AnimationControllerHookState state =
        useHook(_AnimationControllerHook(duration: duration));
    return state.animationController;
  }

  @override
  TickerProvider useTickerProvider() {
    _TickerProviderHookState _tickerProviderHookState =
        useHook(const _TickerProviderHook());
    return _tickerProviderHookState;
  }

  @override
  T useMemoized<T>(T Function() valueBuilder,
      {List parameters = const [], void dispose(T value)}) {
    final _MemoizedHookState<T> state = useHook(
        _MemoizedHook(valueBuilder, dispose: dispose, parameters: parameters));
    return state.value;
  }

  @override
  R useValueChanged<T, R>(T value, R valueChange(T previous, T next)) {
    final _ValueChangedHookState<T, R> state = useHook(_ValueChangedHook(value, valueChange));
    return state.value;
  }
}

abstract class HookWidget extends StatelessWidget {
  const HookWidget({Key key}) : super(key: key);

  @override
  HookElement createElement() => HookElement(this);

  @protected
  @override
  Widget build(covariant HookContext context);
}

abstract class HookContext extends BuildContext {
  HookState<T> useHook<T extends Hook>(T hook);
  ValueNotifier<T> useState<T>({T initialData, void dispose(T value)});
  T useMemoized<T>(T valueBuilder(), {List parameters, void dispose(T value)});
  R useValueChanged<T, R>(T value, R valueChange(T previous, T next));
  // void useListenable(Listenable listenable);
  T useAnimation<T>(Animation<T> animation);
  // T useValueListenable<T>(ValueListenable<T> valueListenable);
  // AsyncSnapshot<T> useStream<T>(Stream<T> stream, {T initialData});
  AnimationController useAnimationController({Duration duration});
  TickerProvider useTickerProvider();
}
