part of 'hooks.dart';

/// Creates a [ExpansibleController] that will be disposed automatically.
///
/// See also:
/// - [ExpansibleController]
ExpansibleController useExpansibleController({List<Object?>? keys}) {
  return use(_ExpansibleControllerHook(keys: keys));
}

/// Creates a [ExpansionTileController] that will be disposed automatically.
///
/// See also:
/// - [ExpansionTileController]
@Deprecated('Use `useExpansibleController` instead.')
ExpansionTileController useExpansionTileController({List<Object?>? keys}) {
  return use(_ExpansibleControllerHook(keys: keys));
}

class _ExpansibleControllerHook extends Hook<ExpansibleController> {
  const _ExpansibleControllerHook({List<Object?>? keys}) : super(keys: keys);

  @override
  HookState<ExpansibleController, Hook<ExpansibleController>> createState() =>
      _ExpansibleControllerHookState();
}

class _ExpansibleControllerHookState
    extends HookState<ExpansibleController, _ExpansibleControllerHook> {
  final controller = ExpansibleController();

  @override
  String get debugLabel => 'useExpansibleController';

  @override
  ExpansibleController build(BuildContext context) => controller;
}
