part of 'hooks.dart';

/// Creates a [TreeSliverController] that will be disposed automatically.
///
/// See also:
/// - [TreeSliverController]
TreeSliverController useTreeSliverController() {
  return use(const _TreeSliverControllerHook());
}

class _TreeSliverControllerHook extends Hook<TreeSliverController> {
  const _TreeSliverControllerHook();

  @override
  HookState<TreeSliverController, Hook<TreeSliverController>> createState() =>
      _TreeSliverControllerHookState();
}

class _TreeSliverControllerHookState
    extends HookState<TreeSliverController, _TreeSliverControllerHook> {
  final controller = TreeSliverController();

  @override
  String get debugLabel => 'useTreeSliverController';

  @override
  TreeSliverController build(BuildContext context) => controller;
}
