part of 'hooks.dart';

/// Creates a [TabController] that will be disposed automatically.
///
/// See also:
/// - [TabController]
TabController useTabController({
  required int initialLength,
  TickerProvider? vsync,
  int initialIndex = 0,
  List<Object?>? keys,
}) {
  vsync ??= useSingleTickerProvider(keys: keys);
  final localVsync = vsync;
  return _useChangeNotifier(
    () => TabController(
      vsync: localVsync,
      length: initialLength,
      initialIndex: initialIndex,
    ),
    keys,
  );
}
