part of 'hooks.dart';

/// Creates a [SearchController] that will be disposed automatically.
///
/// See also:
/// - [SearchController]
@Deprecated(
  'Use `useSearchController` from `package:material_hooks/material_hooks.dart` instead. '
  'The Flutter SDK deprecated its Material and Cupertino libraries in favor of '
  'the `material_ui` package.',
)
SearchController useSearchController({List<Object?>? keys}) {
  return use(_SearchControllerHook(keys: keys));
}

class _SearchControllerHook extends Hook<SearchController> {
  const _SearchControllerHook({List<Object?>? keys}) : super(keys: keys);

  @override
  HookState<SearchController, Hook<SearchController>> createState() =>
      _SearchControllerHookState();
}

class _SearchControllerHookState
    extends HookState<SearchController, _SearchControllerHook> {
  final controller = SearchController();

  @override
  String get debugLabel => 'useSearchController';

  @override
  SearchController build(BuildContext context) => controller;

  @override
  void dispose() => controller.dispose();
}
