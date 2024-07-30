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

/// Adds a given [listener] to a [Listenable] and removes it when the hook is
/// disposed.
///
/// As opposed to `useListenable`, this hook does not mark the widget as needing
/// build when the listener is called. Use this for side effects that do not
/// require a rebuild.
///
/// See also:
///  * [Listenable]
///  * [ValueListenable]
///  * [useListenable]
void useOnListenableChange(
  Listenable? listenable,
  VoidCallback listener,
) {
  return use(_OnListenableChangeHook(listenable, listener));
}

class _OnListenableChangeHook extends Hook<void> {
  const _OnListenableChangeHook(
    this.listenable,
    this.listener,
  );

  final Listenable? listenable;
  final VoidCallback listener;

  @override
  _OnListenableChangeHookState createState() => _OnListenableChangeHookState();
}

class _OnListenableChangeHookState
    extends HookState<void, _OnListenableChangeHook> {
  @override
  void initHook() {
    super.initHook();
    hook.listenable?.addListener(_listener);
  }

  @override
  void didUpdateHook(_OnListenableChangeHook oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.listenable != oldHook.listenable) {
      oldHook.listenable?.removeListener(_listener);
      hook.listenable?.addListener(_listener);
    }
  }

  @override
  void build(BuildContext context) {}

  @override
  void dispose() {
    hook.listenable?.removeListener(_listener);
  }

  /// Wraps `hook.listener` so we have a non-changing reference to it.
  void _listener() {
    hook.listener();
  }

  @override
  String get debugLabel => 'useOnListenableChange';

  @override
  Object? get debugValue => hook.listenable;
}
