part of 'hooks.dart';

/// Creates a [MaterialStatesController] that will be disposed automatically.
///
/// See also:
/// - [MaterialStatesController]
MaterialStatesController useMaterialStatesController({
  Set<MaterialState>? values,
  List<Object?>? keys,
}) {
  return useChangeNotifier(
    () => MaterialStatesController(values),
    'useMaterialStatesController',
    keys,
  );
}
