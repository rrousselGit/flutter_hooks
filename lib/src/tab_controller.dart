part of 'hooks.dart';

/// Creates and disposes a [TabController].
///
/// See also:
/// - [TabController]
TabController useTabController({
  @required TickerProvider vsync,
  @required int length,
  int initialIndex = 0,
  List<Object> keys,
}) {
  return use(_TabControllerHook(
    vsync: vsync,
    length: length,
    initialIndex: initialIndex,
    keys: keys,
  ));
}

class _TabControllerHook extends Hook<TabController> {
  const _TabControllerHook({
    @required this.vsync,
    @required this.length,
    this.initialIndex = 0,
    List<Object> keys,
  }) : super(keys: keys);

  final TickerProvider vsync;
  final int length;
  final int initialIndex;

  @override
  HookState<TabController, Hook<TabController>> createState() =>
      _TabControllerHookState();
}

class _TabControllerHookState
    extends HookState<TabController, _TabControllerHook> {
  TabController controller;

  @override
  void initHook() {
    controller = TabController(
      length: hook.length,
      initialIndex: hook.initialIndex,
      vsync: hook.vsync,
    );
  }

  @override
  TabController build(BuildContext context) => controller;

  @override
  void dispose() => controller?.dispose();
}
