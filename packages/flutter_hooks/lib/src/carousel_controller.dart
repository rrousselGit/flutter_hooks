part of 'hooks.dart';

/// Creates a [CarouselController] that will be disposed automatically.
///
/// See also:
/// - [CarouselController]
CarouselController useCarouselController({
  int initialItem = 0,
  List<Object?>? keys,
}) {
  return use(
    _CarouselControllerHook(
      initialItem: initialItem,
      keys: keys,
    ),
  );
}

class _CarouselControllerHook extends Hook<CarouselController> {
  const _CarouselControllerHook({
    required this.initialItem,
    super.keys,
  });

  final int initialItem;

  @override
  HookState<CarouselController, Hook<CarouselController>> createState() =>
      _CarouselControllerHookState();
}

class _CarouselControllerHookState
    extends HookState<CarouselController, _CarouselControllerHook> {
  late final controller = CarouselController(
    initialItem: hook.initialItem,
  );

  @override
  CarouselController build(BuildContext context) => controller;

  @override
  void dispose() => controller.dispose();

  @override
  String get debugLabel => 'useCarouselController';
}
