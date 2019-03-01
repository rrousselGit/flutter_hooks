part of 'hooks.dart';

/// Subscribes to a [ValueListenable] and return its value.
///
/// See also:
///   * [ValueListenable]
///   * [useListenable], [useAnimation], [useStream]
T useValueListenable<T>(ValueListenable<T> valueListenable) {
  useListenable(valueListenable);
  return valueListenable.value;
}

/// Subscribes to a [Listenable] and mark the widget as needing build
/// whenever the listener is called.
///
/// See also:
///   * [Listenable]
///   * [useValueListenable], [useAnimation], [useStream]
void useListenable(Listenable listenable) {
  Hook.use(_ListenableHook(listenable));
}

class _ListenableHook extends Hook<void> {
  final Listenable listenable;

  const _ListenableHook(this.listenable) : assert(listenable != null);

  @override
  _ListenableStateHook createState() => _ListenableStateHook();
}

class _ListenableStateHook extends HookState<void, _ListenableHook> {
  @override
  void initHook() {
    super.initHook();
    hook.listenable.addListener(_listener);
  }

  @override
  void didUpdateHook(_ListenableHook oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.listenable != oldHook.listenable) {
      oldHook.listenable.removeListener(_listener);
      hook.listenable.addListener(_listener);
    }
  }

  @override
  void build(BuildContext context) {}

  void _listener() {
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    hook.listenable.removeListener(_listener);
  }
}

/// Creates a [ValueNotifier] automatically disposed.
///
/// As opposed to `useState`, this hook do not subscribes to [ValueNotifier].
/// This allows a more granular rebuild.
///
/// See also:
///   * [ValueNotifier]
///   * [useValueListenable]
ValueNotifier<T> useValueNotifier<T>([T intialData, List keys]) {
  return Hook.use(_ValueNotifierHook(
    initialData: intialData,
    keys: keys,
  ));
}

class _ValueNotifierHook<T> extends Hook<ValueNotifier<T>> {
  final T initialData;

  const _ValueNotifierHook({List keys, this.initialData}) : super(keys: keys);

  @override
  _UseValueNotiferHookState<T> createState() => _UseValueNotiferHookState<T>();
}

class _UseValueNotiferHookState<T>
    extends HookState<ValueNotifier<T>, _ValueNotifierHook<T>> {
  ValueNotifier<T> notifier;

  @override
  void initHook() {
    super.initHook();
    notifier = ValueNotifier(hook.initialData);
  }

  @override
  ValueNotifier<T> build(BuildContext context) {
    return notifier;
  }

  @override
  void dispose() {
    notifier.dispose();
    super.dispose();
  }
}
