part of 'hooks.dart';

/// Subscribes to a [ValueListenable] and returns its value.
///
/// See also:
///   * [ValueListenable], the created object
///   * [useListenable]
T useValueListenable<T>(ValueListenable<T> valueListenable) {
  use(_UseValueListenableHook(valueListenable));
  return valueListenable.value;
}

class _UseValueListenableHook extends _ListenableHook {
  const _UseValueListenableHook(ValueListenable<Object?> animation)
      : super(animation);

  @override
  _UseValueListenableStateHook createState() {
    return _UseValueListenableStateHook();
  }
}

class _UseValueListenableStateHook extends _ListenableStateHook {
  @override
  String get debugLabel => 'useValueListenable';

  @override
  Object? get debugValue => (hook.listenable as ValueListenable?)?.value;
}

/// Subscribes to a [Listenable] and marks the widget as needing build
/// whenever the listener is called.
///
/// See also:
///   * [Listenable]
///   * [useValueListenable], [useAnimation]
T useListenable<T extends Listenable?>(T listenable) {
  use(_ListenableHook(listenable));
  return listenable;
}

class _ListenableHook extends Hook<void> {
  const _ListenableHook(this.listenable);

  final Listenable? listenable;

  @override
  _ListenableStateHook createState() => _ListenableStateHook();
}

class _ListenableStateHook extends HookState<void, _ListenableHook> {
  @override
  void initHook() {
    super.initHook();
    hook.listenable?.addListener(_listener);
  }

  @override
  void didUpdateHook(_ListenableHook oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.listenable != oldHook.listenable) {
      oldHook.listenable?.removeListener(_listener);
      hook.listenable?.addListener(_listener);
    }
  }

  @override
  void build(BuildContext context) {}

  void _listener() {
    setState(() {});
  }

  @override
  void dispose() {
    hook.listenable?.removeListener(_listener);
  }

  @override
  String get debugLabel => 'useListenable';

  @override
  Object? get debugValue => hook.listenable;
}

/// Creates a [ValueNotifier] that is automatically disposed.
///
/// As opposed to `useState`, this hook does not subscribe to [ValueNotifier].
/// This allows a more granular rebuild.
///
/// See also:
///   * [ValueNotifier]
///   * [useValueListenable]
ValueNotifier<T> useValueNotifier<T>(T initialData, [List<Object?>? keys]) {
  return use(
    _ValueNotifierHook(
      initialData: initialData,
      keys: keys,
    ),
  );
}

class _ValueNotifierHook<T> extends Hook<ValueNotifier<T>> {
  const _ValueNotifierHook({List<Object?>? keys, required this.initialData})
      : super(keys: keys);

  final T initialData;

  @override
  _UseValueNotifierHookState<T> createState() =>
      _UseValueNotifierHookState<T>();
}

class _UseValueNotifierHookState<T>
    extends HookState<ValueNotifier<T>, _ValueNotifierHook<T>> {
  late final notifier = ValueNotifier<T>(hook.initialData);

  @override
  ValueNotifier<T> build(BuildContext context) {
    return notifier;
  }

  @override
  void dispose() {
    notifier.dispose();
  }

  @override
  String get debugLabel => 'useValueNotifier';
}

/// Subscribes to a [Listenable] and registers `listener` to the passed `listenable`.
///
/// See also:
///   * [useListenable]
///   * [useEffect]
void useOnListenableChange(VoidCallback listener, Listenable listenable) {
  use(_OnListenableChangeHook(listener, listenable));
}

class _OnListenableChangeHook extends Hook<void> {
  _OnListenableChangeHook(this.listener, this.listenable)
      : super(keys: [listenable]);

  final VoidCallback listener;
  final Listenable listenable;

  @override
  _OnListenableChangeHookState createState() => _OnListenableChangeHookState();
}

class _OnListenableChangeHookState
    extends HookState<void, _OnListenableChangeHook> {
  Dispose? disposer;

  @override
  void initHook() {
    super.initHook();
    scheduleEffect();
  }

  @override
  void didUpdateHook(_OnListenableChangeHook oldHook) {
    super.didUpdateHook(oldHook);

    if (hook.keys == null) {
      disposer?.call();
      scheduleEffect();
    }
  }

  @override
  void build(BuildContext context) {}

  @override
  void dispose() => disposer?.call();

  void scheduleEffect() {
    hook.listenable.addListener(hook.listener);
    disposer = () => hook.listenable.removeListener(hook.listener);
  }

  @override
  String get debugLabel => 'useOnListenableChange';

  @override
  bool get debugSkipValue => true;
}
