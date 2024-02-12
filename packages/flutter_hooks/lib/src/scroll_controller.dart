part of 'hooks.dart';

/// Creates [ScrollController] that will be disposed automatically.
///
/// See also:
/// - [ScrollController]
ScrollController useScrollController({
  double initialScrollOffset = 0.0,
  bool keepScrollOffset = true,
  String? debugLabel,
  List<Object?>? keys,
}) {
  return useChangeNotifier(
    () => ScrollController(
      initialScrollOffset: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      debugLabel: debugLabel,
    ),
    'useScrollController',
    keys,
  );
}
