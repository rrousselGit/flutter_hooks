part of 'hooks.dart';

/// Creates a [ExpansionTileController] that will be disposed automatically.
///
/// See also:
/// - [ExpansionTileController]
ExpansionTileController useExpansionTileController({List<Object?>? keys}) {
  return use(_ExpansionTileControllerHook(keys: keys));
}

class _ExpansionTileControllerHook extends Hook<ExpansionTileController> {
  const _ExpansionTileControllerHook({List<Object?>? keys}) : super(keys: keys);

  @override
  HookState<ExpansionTileController, Hook<ExpansionTileController>>
      createState() => _ExpansionTileControllerHookState();
}

class _ExpansionTileControllerHookState
    extends HookState<ExpansionTileController, _ExpansionTileControllerHook> {
  final controller = ExpansionTileController();

  @override
  String get debugLabel => 'useExpansionTileController';

  @override
  ExpansionTileController build(BuildContext context) => controller;
}
