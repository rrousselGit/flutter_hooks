part of 'hooks.dart';

/// widget ignore updates accordingly after a specified [duration] duration.
///
/// Example:
/// ```dart
/// String userInput = ''; // Your input value
///
/// // Create a throttle callback
/// final throttle = useThrottle(duration: const Duration(milliseconds: 500));
/// // Assume a fetch method fetchData(String query) exists
/// Button(onPressed: () => throttle(() => fetchData(userInput)));
/// ```
void Function(VoidCallback callback) useThrottle({
  Duration duration = const Duration(milliseconds: 500),
}) {
  final throttler = useMemoized(() => _Throttler(duration), [duration]);
  return throttler.run;
}

class _Throttler {
  _Throttler(this.duration)
      : assert(
          0 < duration.inMilliseconds,
          'duration must be greater than 0ms',
        );

  final Duration duration;

  Timer? _timer;

  bool get _isRunning => _timer != null;

  void run(VoidCallback callback) {
    if (!_isRunning) {
      _timer = Timer(duration, () {
        _timer = null;
      });
      callback();
    }
  }
}
