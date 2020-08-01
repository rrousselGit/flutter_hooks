part of 'hooks.dart';

/// Returns an [IsMounted] object that you can use
/// to check if the [State] is mounted.
/// ```dart
/// final isMounted = useIsMounted();
/// useEffect((){
///   myFuture.then((){
///     if (isMounted()) {
///       // Do something
///     }
///   });
///   return null;
/// }, []);
/// ```
/// See also:
///   * The [State.mounted] property.
IsMounted useIsMounted() {
  final isMounted = IsMounted();
  useEffect(() {
    return () {
      isMounted._mounted = false;
    };
  }, const []);
  return isMounted;
}

/// Mutable class that holds the current mounted value.
/// See also:
///   * The [State.mounted] property
class IsMounted {
  bool _mounted = true;

  /// Returns whether or not the state is mounted.
  bool call() {
    return _mounted;
  }
}
