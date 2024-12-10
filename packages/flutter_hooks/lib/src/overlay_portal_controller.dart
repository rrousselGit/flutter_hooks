part of 'hooks.dart';

/// Creates a [OverlayPortalController] that will be disposed automatically.
///
/// See also:
/// - [OverlayPortalController]
OverlayPortalController useOverlayPortalController({
  List<Object?>? keys,
}) {
  return use(_OverlayPortalControllerHook(keys: keys));
}

class _OverlayPortalControllerHook extends Hook<OverlayPortalController> {
  const _OverlayPortalControllerHook({List<Object?>? keys}) : super(keys: keys);

  @override
  HookState<OverlayPortalController, Hook<OverlayPortalController>>
      createState() => _OverlayPortalControllerHookState();
}

class _OverlayPortalControllerHookState
    extends HookState<OverlayPortalController, _OverlayPortalControllerHook> {
  final controller = OverlayPortalController();

  @override
  OverlayPortalController build(BuildContext context) => controller;

  @override
  String get debugLabel => 'useOverlayPortalController';
}
