part of 'hook.dart';

@immutable
abstract class Hook {
  const Hook();

  HookState createState();
}

class HookState<T extends Hook> {
  Element _element;
  // voluntarily not a HookContext so that life-cycles cannot use hooks
  BuildContext get context => _element;
  T _hook;
  T get hook => _hook;
  void initHook() {}
  void dispose() {}
  void build(HookContext context) {}
  void didUpdateHook(covariant Hook oldHook) {}
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
