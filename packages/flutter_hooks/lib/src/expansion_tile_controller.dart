part of 'hooks.dart';

/// Creates a [ExpansionTileController] that will be disposed automatically.
///
/// See also:
/// - [ExpansionTileController]
ExpansionTileController useExpansionTileController({List<Object?>? keys}) {
  return useDispose(
    ExpansionTileController.new,
    (_) {},
    'useExpansionTileController',
    keys,
  );
}
