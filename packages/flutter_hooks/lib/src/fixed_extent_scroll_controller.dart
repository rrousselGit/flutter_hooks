part of 'hooks.dart';

/// Creates [FixedExtentScrollController] that will be disposed automatically.
///
/// See also:
/// - [FixedExtentScrollController]
FixedExtentScrollController useFixedExtentScrollController({
  int initialItem = 0,
  ScrollControllerCallback? onAttach,
  ScrollControllerCallback? onDetach,
  List<Object?>? keys,
}) {
  return _useChangeNotifier(
    () {
      return FixedExtentScrollController(
        initialItem: initialItem,
        onAttach: onAttach,
        onDetach: onDetach,
      );
    },
    keys,
  );
}
