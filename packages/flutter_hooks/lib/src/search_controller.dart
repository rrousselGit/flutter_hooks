part of 'hooks.dart';

/// Creates a [SearchController] that will be disposed automatically.
///
/// See also:
/// - [SearchController]
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
