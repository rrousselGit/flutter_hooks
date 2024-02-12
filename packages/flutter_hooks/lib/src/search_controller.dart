part of 'hooks.dart';

/// Creates a [SearchController] that will be disposed automatically.
///
/// See also:
/// - [SearchController]
SearchController useSearchController({List<Object?>? keys}) {
  return useChangeNotifier(
    SearchController.new,
    'useSearchController',
    keys,
  );
}
