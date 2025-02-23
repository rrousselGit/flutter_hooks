part of 'hooks.dart';

/// Creates a [TabController] that will be disposed automatically.
///
/// See also:
/// - [TabController]
TabController useTabController({
  required int initialLength,
  Duration? animationDuration = kTabScrollDuration,
  TickerProvider? vsync,
  int initialIndex = 0,
  List<Object?>? keys,
}) {
  vsync ??= useSingleTickerProvider(keys: keys);

  return use(
    _TabControllerHook(
      vsync: vsync,
      length: initialLength,
      initialIndex: initialIndex,
      animationDuration: animationDuration,
      keys: keys,
    ),
  );
}

class _TabControllerHook extends Hook<TabController> {
  const _TabControllerHook({
    required this.length,
    required this.vsync,
    required this.initialIndex,
    required this.animationDuration,
    super.keys,
  });

  final int length;
  final TickerProvider vsync;
  final int initialIndex;
  final Duration? animationDuration;

  @override
  HookState<TabController, Hook<TabController>> createState() =>
      _TabControllerHookState();
}

class _TabControllerHookState
    extends HookState<TabController, _TabControllerHook> {
  late final controller = TabController(
    length: hook.length,
    initialIndex: hook.initialIndex,
    animationDuration: hook.animationDuration,
    vsync: hook.vsync,
  );

  @override
  TabController build(BuildContext context) => controller;

  @override
  void dispose() => controller.dispose();

  @override
  String get debugLabel => 'useTabController';
}
