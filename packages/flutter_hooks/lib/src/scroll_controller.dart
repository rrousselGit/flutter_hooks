part of 'hooks.dart';

class _ScrollControllerCreator {
  const _ScrollControllerCreator();

  ScrollController call({
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    String? debugLabel,
    List<Object?>? keys,
  }) {
    return use(
      _ScrollControllerHook(
        builder: () => ScrollController(
          initialScrollOffset: initialScrollOffset,
          keepScrollOffset: keepScrollOffset,
          debugLabel: debugLabel,
        ),
        keys: keys,
      ),
    );
  }

  T build<T extends ScrollController>(
    T Function() builder, {
    List<Object?>? keys,
  }) {
    return use(_ScrollControllerHook(builder: builder, keys: keys)) as T;
  }
}

/// Creates and disposes a [ScrollController].
///
/// See also:
/// - [ScrollController]
///
/// For custom scroll controllers (like [FixedExtentScrollController])
///
const useScrollController = _ScrollControllerCreator();

class _ScrollControllerHook extends Hook<ScrollController> {
  const _ScrollControllerHook({required this.builder, List<Object?>? keys})
      : super(keys: keys);

  final ScrollController Function() builder;

  @override
  _ScrollControllerHookState createState() => _ScrollControllerHookState();
}

class _ScrollControllerHookState
    extends HookState<ScrollController, _ScrollControllerHook> {
  late final ScrollController controller = hook.builder();

  @override
  ScrollController build(BuildContext context) => controller;

  @override
  void dispose() => controller.dispose();

  @override
  String get debugLabel => 'useScrollController';
}
