part of 'hook.dart';

/// [Hook] is similar to a [StatelessWidget], but is not associated
/// to an [Element].
///
/// A [Hook] is typically the equivalent of [State] for [StatefulWidget],
/// with the notable difference that a [HookWidget] can have more than one [Hook].
/// A [Hook] is created within the [build] method of [HookWidget] and the creation
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
/// They are used to extract logic that depends on a [Widget] life-cycle (such as [dispose]).
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
/// [useAnimationController]
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

/// The logic and internal state for a [HookWidget]
///
/// A [HookState]
class HookState<T extends Hook> {
  Element _element;

  // voluntarily not a HookContext so that life-cycles cannot use hooks
  /// The location in the tree where this widget builds.
  ///
  /// The framework associates [HookState] objects with a [BuildContext] after creating them with [Hook.createState] and before calling initState. The association is permanent: the [HookState] object will never change its [BuildContext]. However, the [HookContext] itself can be moved around the tree.
  ///
  /// After calling dispose, the framework severs the State object's connection with the BuildContext.
  @protected
  BuildContext get context => _element;

  T _hook;

  /// The current [Hook] associated to this [HookState].
  ///
  /// When this value change, [didUpdateHook] is called.
  T get hook => _hook;

  @protected
  @mustCallSuper
  void initHook() {}

  @protected
  @mustCallSuper
  void dispose() {}

  @protected
  @mustCallSuper
  void build(HookContext context) {}

  @protected
  @mustCallSuper
  void didUpdateHook(covariant Hook oldHook) {}

  @protected
  void setState(VoidCallback callback) {
    // TODO: use official setState
    callback();
    _element.markNeedsBuild();
  }
}

class HookElement extends StatelessElement implements HookContext {
  int _hooksIndex;
  List<HookState> _hooks;

  bool _debugIsBuilding;

  HookElement(HookWidget widget) : super(widget);

  @override
  HookWidget get widget => super.widget;

  HookState<T> useHook<T extends Hook>(T hook) {
    assert(_debugIsBuilding == true, '''
    Hooks should only be called within the build method of a widget.
    Calling them outside of build method leads to an unstable state and is therefore prohibited
    ''');

    final int hooksIndex = _hooksIndex;
    _hooksIndex++;
    _hooks ??= [];

    HookState state;
    if (hooksIndex >= _hooks.length) {
      state = hook.createState()
        .._element = this
        .._hook = hook
        ..initHook();
      _hooks.add(state);
    } else {
      state = _hooks[hooksIndex];
      if (!identical(state._hook, hook)) {
        // TODO: compare type for potential reassemble
        final Hook previousHook = state._hook;
        state._hook = hook;
        state.didUpdateHook(previousHook);
      }
    }
    return state..build(this);
  }

  AsyncSnapshot<T> useStream<T>(Stream<T> stream, {T initialData}) {
    final _StreamHookState<T> state =
        useHook(_StreamHook<T>(stream: stream, initialData: initialData));
    return state.snapshot;
  }

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
  T useAnimation<T>(Animation<T> animation) {
    throw new UnimplementedError();
  }

  @override
  void useListenable(Listenable listenable) {
    throw new UnimplementedError();
  }

  @override
  ValueNotifier<T> useState<T>([T initialData]) {
    throw new UnimplementedError();
  }

  @override
  void unmount() {
    super.unmount();
    if (_hooks != null) {
      for (final hook in _hooks) {
        hook.dispose();

        /// TODO: try catch
        /// See [ChangeNotfier] for what to do in catch
      }
    }
  }

  @override
  T useValueListenable<T>(ValueListenable<T> valueListenable) {
    throw new UnimplementedError();
  }

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
}

abstract class HookWidget extends StatelessWidget {
  const HookWidget({Key key}) : super(key: key);

  @override
  HookElement createElement() => HookElement(this);

  @protected
  Widget build(covariant HookContext context);
}

abstract class HookContext extends BuildContext {
  HookState<T> useHook<T extends Hook>(T hook);
  void useListenable(Listenable listenable);
  T useAnimation<T>(Animation<T> animation);
  T useValueListenable<T>(ValueListenable<T> valueListenable);
  ValueNotifier<T> useState<T>(T initialData);
  AsyncSnapshot<T> useStream<T>(Stream<T> stream, {T initialData});
  AnimationController useAnimationController({Duration duration});
  TickerProvider useTickerProvider();
}
