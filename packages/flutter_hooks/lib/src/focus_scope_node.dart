part of 'hooks.dart';

/// Creates an automatically disposed [FocusScopeNode].
///
/// See also:
/// - [FocusScopeNode]
FocusScopeNode useFocusScopeNode({
  String? debugLabel,
  FocusOnKeyEventCallback? onKeyEvent,
  bool skipTraversal = false,
  bool canRequestFocus = true,
}) {
  return use(
    _FocusScopeNodeHook(
      debugLabel: debugLabel,
      onKeyEvent: onKeyEvent,
      skipTraversal: skipTraversal,
      canRequestFocus: canRequestFocus,
    ),
  );
}

class _FocusScopeNodeHook extends Hook<FocusScopeNode> {
  const _FocusScopeNodeHook({
    this.debugLabel,
    this.onKeyEvent,
    required this.skipTraversal,
    required this.canRequestFocus,
  });

  final String? debugLabel;
  final FocusOnKeyEventCallback? onKeyEvent;
  final bool skipTraversal;
  final bool canRequestFocus;

  @override
  _FocusScopeNodeHookState createState() {
    return _FocusScopeNodeHookState();
  }
}

class _FocusScopeNodeHookState
    extends HookState<FocusScopeNode, _FocusScopeNodeHook> {
  late final FocusScopeNode _focusScopeNode = FocusScopeNode(
    debugLabel: hook.debugLabel,
    onKeyEvent: hook.onKeyEvent,
    skipTraversal: hook.skipTraversal,
    canRequestFocus: hook.canRequestFocus,
  );

  @override
  void didUpdateHook(_FocusScopeNodeHook oldHook) {
    _focusScopeNode
      ..debugLabel = hook.debugLabel
      ..skipTraversal = hook.skipTraversal
      ..canRequestFocus = hook.canRequestFocus
      ..onKeyEvent = hook.onKeyEvent;
  }

  @override
  FocusScopeNode build(BuildContext context) => _focusScopeNode;

  @override
  void dispose() => _focusScopeNode.dispose();

  @override
  String get debugLabel => 'useFocusScopeNode';
}
