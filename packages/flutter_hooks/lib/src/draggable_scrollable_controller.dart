part of 'hooks.dart';

/// Creates a [DraggableScrollableController] that will be disposed automatically.
///
/// See also:
/// - [DraggableScrollableController]
DraggableScrollableController useDraggableScrollableController(
    {List<Object?>? keys}) {
  return use(_DraggableScrollableControllerHook(keys: keys));
}

class _DraggableScrollableControllerHook
    extends Hook<DraggableScrollableController> {
  const _DraggableScrollableControllerHook({List<Object?>? keys})
      : super(keys: keys);

  @override
  HookState<DraggableScrollableController, Hook<DraggableScrollableController>>
      createState() => _DraggableScrollableControllerHookState();
}

class _DraggableScrollableControllerHookState extends HookState<
    DraggableScrollableController, _DraggableScrollableControllerHook> {
  final controller = DraggableScrollableController();

  @override
  String get debugLabel => 'useDraggableScrollableController';

  @override
  DraggableScrollableController build(BuildContext context) => controller;
}
