part of 'hooks.dart';

/// Creates and disposes a [SnapshotController].
///
/// Note that [allowSnapshotting] must be set to `true`
/// in order for this controller to actually do anything.
/// This is consistent with [SnapshotController.new].
///
/// If [allowSnapshotting] changes on subsequent calls to [useSnapshotController],
/// [SnapshotController.allowSnapshotting] will be called to update accordingly.
///
/// ```dart
/// final controller = useSnapshotController(allowSnapshotting: true);
/// // is equivalent to
/// final controller = useSnapshotController();
/// controller.allowSnapshotting = true;
/// ```
///
/// See also:
/// - [SnapshotController]
SnapshotController useSnapshotController({
  bool allowSnapshotting = false,
}) {
  return use(
    _SnapshotControllerHook(
      allowSnapshotting: allowSnapshotting,
    ),
  );
}

class _SnapshotControllerHook extends Hook<SnapshotController> {
  const _SnapshotControllerHook({
    required this.allowSnapshotting,
  });

  final bool allowSnapshotting;

  @override
  HookState<SnapshotController, Hook<SnapshotController>> createState() =>
      _SnapshotControllerHookState();
}

class _SnapshotControllerHookState
    extends HookState<SnapshotController, _SnapshotControllerHook> {
  late final controller =
      SnapshotController(allowSnapshotting: hook.allowSnapshotting);

  @override
  void didUpdateHook(_SnapshotControllerHook oldHook) {
    super.didUpdateHook(oldHook);
    controller.allowSnapshotting = hook.allowSnapshotting;
  }

  @override
  SnapshotController build(BuildContext context) => controller;

  @override
  void dispose() => controller.dispose();

  @override
  String get debugLabel => 'useSnapshotController';
}
