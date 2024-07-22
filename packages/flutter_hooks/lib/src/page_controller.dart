part of 'hooks.dart';

/// Creates a [PageController] that will be disposed automatically.
///
/// See also:
/// - [PageController]
PageController usePageController({
  int initialPage = 0,
  bool keepPage = true,
  double viewportFraction = 1.0,
  ScrollControllerCallback? onAttach,
  ScrollControllerCallback? onDetach,
  List<Object?>? keys,
}) {
  return use(
    _PageControllerHook(
      initialPage: initialPage,
      keepPage: keepPage,
      viewportFraction: viewportFraction,
      onAttach: onAttach,
      onDetach: onDetach,
      keys: keys,
    ),
  );
}

class _PageControllerHook extends Hook<PageController> {
  const _PageControllerHook({
    required this.initialPage,
    required this.keepPage,
    required this.viewportFraction,
    this.onAttach,
    this.onDetach,
    List<Object?>? keys,
  }) : super(keys: keys);

  final int initialPage;
  final bool keepPage;
  final double viewportFraction;
  final ScrollControllerCallback? onAttach;
  final ScrollControllerCallback? onDetach;

  @override
  HookState<PageController, Hook<PageController>> createState() =>
      _PageControllerHookState();
}

class _PageControllerHookState
    extends HookState<PageController, _PageControllerHook> {
  late final controller = PageController(
    initialPage: hook.initialPage,
    keepPage: hook.keepPage,
    viewportFraction: hook.viewportFraction,
    onAttach: hook.onAttach,
    onDetach: hook.onDetach,
  );

  @override
  PageController build(BuildContext context) => controller;

  @override
  void dispose() => controller.dispose();

  @override
  String get debugLabel => 'usePageController';
}
