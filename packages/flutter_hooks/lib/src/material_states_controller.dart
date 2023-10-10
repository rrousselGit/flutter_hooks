part of 'hooks.dart';

/// Creates a [MaterialStatesController] that will be disposed automatically.
///
/// See also:
/// - [MaterialStatesController]
MaterialStatesController useMaterialStatesController({
  Set<MaterialState>? values,
  List<Object?>? keys,
}) {
  return use(
    _MaterialStatesControllerHook(
      values: values,
      keys: keys,
    ),
  );
}

class _MaterialStatesControllerHook extends Hook<MaterialStatesController> {
  const _MaterialStatesControllerHook({
    required this.values,
    super.keys,
  });

  final Set<MaterialState>? values;

  @override
  HookState<MaterialStatesController, Hook<MaterialStatesController>>
      createState() => _MaterialStateControllerHookState();
}

class _MaterialStateControllerHookState
    extends HookState<MaterialStatesController, _MaterialStatesControllerHook> {
  late final controller = MaterialStatesController(hook.values);

  @override
  MaterialStatesController build(BuildContext context) => controller;

  @override
  void dispose() => controller.dispose();

  @override
  String get debugLabel => 'useMaterialStatesController';
}
