part of 'hooks.dart';

/// Creates a [CarouselController] that will be disposed automatically.
///
/// See also:
/// - [CarouselController]
@Deprecated(
  'Use `useCarouselController` from `package:material_hooks/material_hooks.dart` instead. '
  'The Flutter SDK deprecated its Material and Cupertino libraries in favor of '
  'the `material_ui` package.',
)
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
