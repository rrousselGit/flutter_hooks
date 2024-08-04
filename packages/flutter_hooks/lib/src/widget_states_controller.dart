part of 'hooks.dart';

/// Creates a [WidgetStatesController] that will be disposed automatically.
///
/// See also:
/// - [WidgetStatesController]
WidgetStatesController useWidgetStatesController({
  Set<WidgetState>? values,
  List<Object?>? keys,
}) {
  return _useChangeNotifier(() => WidgetStatesController(values), keys);
}
