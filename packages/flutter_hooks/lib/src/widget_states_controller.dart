part of 'hooks.dart';

/// Creates a [WidgetStatesController] that will be disposed automatically.
///
/// See also:
/// - [WidgetStatesController]
WidgetStatesController useWidgetStatesController({
  Set<WidgetState>? values,
  List<Object?>? keys,
}) {
  return use(
    _WidgetStatesControllerHook(
      values: values,
      keys: keys,
    ),
  );
}

class _WidgetStatesControllerHook extends Hook<WidgetStatesController> {
  const _WidgetStatesControllerHook({
    required this.values,
    super.keys,
  });

  final Set<WidgetState>? values;

  @override
  HookState<WidgetStatesController, Hook<WidgetStatesController>>
      createState() => _WidgetStateControllerHookState();
}

class _WidgetStateControllerHookState
    extends HookState<WidgetStatesController, _WidgetStatesControllerHook> {
  late final controller = WidgetStatesController(hook.values);

  @override
  WidgetStatesController build(BuildContext context) => controller;

  @override
  void dispose() => controller.dispose();

  @override
  String get debugLabel => 'useWidgetStatesController';
}
