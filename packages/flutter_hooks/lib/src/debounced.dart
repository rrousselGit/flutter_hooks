part of 'hooks.dart';

/// Returns a debounced version of the provided value [toDebounce], triggering
/// widget updates accordingly after a specified [timeout] duration.
///
/// Example:
/// ```dart
/// String userInput = ''; // Your input value
///
/// // Create a debounced version of userInput
/// final debouncedInput = useDebounced(
///   userInput,
///   Duration(milliseconds: 500), // Set your desired timeout
/// );
/// // Assume a fetch method fetchData(String query) exists
/// useEffect(() {
///   fetchData(debouncedInput); // Use debouncedInput as a dependency
///   return null;
/// }, [debouncedInput]);
/// ```
T? useDebounced<T>(
  T toDebounce,
  Duration timeout,
) {
  return use(
    _DebouncedHook(
      toDebounce: toDebounce,
      timeout: timeout,
    ),
  );
}

class _DebouncedHook<T> extends Hook<T?> {
  const _DebouncedHook({
    required this.toDebounce,
    required this.timeout,
  });

  final T toDebounce;
  final Duration timeout;

  @override
  _DebouncedHookState<T> createState() => _DebouncedHookState();
}

class _DebouncedHookState<T> extends HookState<T?, _DebouncedHook<T>> {
  T? _state;
  Timer? _timer;

  @override
  void initHook() {
    super.initHook();
    _startDebounce(hook.toDebounce);
  }

  void _startDebounce(T toDebounce) {
    _timer?.cancel();
    _timer = Timer(hook.timeout, () {
      setState(() {
        _state = toDebounce;
      });
    });
  }

  @override
  void didUpdateHook(_DebouncedHook<T> oldHook) {
    if (hook.toDebounce != oldHook.toDebounce ||
        hook.timeout != oldHook.timeout) {
      _startDebounce(hook.toDebounce);
    }
  }

  @override
  T? build(BuildContext context) => _state;

  @override
  Object? get debugValue => _state;

  @override
  String get debugLabel => 'useDebounced<$T>';

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
