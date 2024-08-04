part of 'hooks.dart';

/// Creates a [PageController] that will be disposed automatically.
///
/// See also:
/// - [PageController]
PageController usePageController({
  int initialPage = 0,
  bool keepPage = true,
  double viewportFraction = 1.0,
  ScrollControllerCallback? onAttach,
  ScrollControllerCallback? onDetach,
  List<Object?>? keys,
}) {
  return _useChangeNotifier(
    () => PageController(
      initialPage: initialPage,
      keepPage: keepPage,
      viewportFraction: viewportFraction,
      onAttach: onAttach,
      onDetach: onDetach,
    ),
    keys,
  );
}
