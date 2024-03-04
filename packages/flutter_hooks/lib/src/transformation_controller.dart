part of 'hooks.dart';

/// Creates and disposes a [TransformationController].
///
/// See also:
/// - [TransformationController]
TransformationController useTransformationController({
  Matrix4? initialValue,
  List<Object?>? keys,
}) {
  return useChangeNotifier(
    () => TransformationController(initialValue),
    'useTransformationController',
    keys,
  );
}
