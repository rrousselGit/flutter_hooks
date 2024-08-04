part of 'hooks.dart';

/// Creates a [DraggableScrollableController] that will be disposed automatically.
///
/// See also:
/// - [DraggableScrollableController]
DraggableScrollableController useDraggableScrollableController({
  List<Object?>? keys,
}) {
  return _useChangeNotifier(DraggableScrollableController.new, keys);
}
