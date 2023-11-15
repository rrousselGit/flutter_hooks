part of 'hooks.dart';

/// Returns a [ValueNotifier] that updates its value with a timeout
/// for the given input [toDebounce] and triggers widget rebuilds accordingly.
ValueNotifier<T?> useDebounced<T>(
  T toDebounce, {
  Duration timeout = const Duration(milliseconds: 500),
}) {
  return use(
    _DebouncedHook(
      toDebounce: toDebounce,
      timeout: timeout,
    ),
  );
}

class _DebouncedHook<T> extends Hook<ValueNotifier<T?>> {
  const _DebouncedHook({
    required this.toDebounce,
    required this.timeout,
  });

  final T toDebounce;
  final Duration timeout;

  @override
  _DebouncedHookState<T> createState() => _DebouncedHookState();
}

class _DebouncedHookState<T>
    extends HookState<ValueNotifier<T?>, _DebouncedHook<T>> {
  final ValueNotifier<T?> _state = ValueNotifier(null);
  Timer? _timer;

  @override
  void initHook() {
    super.initHook();
    _startDebounce(hook.toDebounce);
  }

  void _startDebounce(T toDebounce) {
    _timer?.cancel();
    _timer = Timer(hook.timeout, () {
      if (context.mounted) {
        _state.value = toDebounce;
        setState(() {});
      }
    });
  }

  @override
  void didUpdateHook(_DebouncedHook<T> oldHook) {
    if (hook.toDebounce != oldHook.toDebounce) {
      _startDebounce(hook.toDebounce);
    }
  }

  @override
  ValueNotifier<T?> build(BuildContext context) => _state;

  @override
  Object? get debugValue => _state.value;

  @override
  String get debugLabel => 'useDebounced<$T>';

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _state.dispose();
    super.dispose();
  }
}
