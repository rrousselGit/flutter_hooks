part of 'hooks.dart';

/// Creates an automatically disposed [FocusNode].
///
/// See also:
/// - [FocusNode]
FocusNode useFocusNode({
  String? debugLabel,
  FocusOnKeyEventCallback? onKeyEvent,
  bool skipTraversal = false,
  bool canRequestFocus = true,
  bool descendantsAreFocusable = true,
  bool descendantsAreTraversable = true,
}) {
  return use(
    _FocusNodeHook(
      debugLabel: debugLabel,
      onKeyEvent: onKeyEvent,
      skipTraversal: skipTraversal,
      canRequestFocus: canRequestFocus,
      descendantsAreFocusable: descendantsAreFocusable,
      descendantsAreTraversable: descendantsAreTraversable,
    ),
  );
}

class _FocusNodeHook extends Hook<FocusNode> {
  const _FocusNodeHook({
    this.debugLabel,
    this.onKeyEvent,
    required this.skipTraversal,
    required this.canRequestFocus,
    required this.descendantsAreFocusable,
    required this.descendantsAreTraversable,
  });

  final String? debugLabel;
  final FocusOnKeyEventCallback? onKeyEvent;
  final bool skipTraversal;
  final bool canRequestFocus;
  final bool descendantsAreFocusable;
  final bool descendantsAreTraversable;

  @override
  _FocusNodeHookState createState() {
    return _FocusNodeHookState();
  }
}

class _FocusNodeHookState extends HookState<FocusNode, _FocusNodeHook> {
  late final FocusNode _focusNode = FocusNode(
    debugLabel: hook.debugLabel,
    onKeyEvent: hook.onKeyEvent,
    skipTraversal: hook.skipTraversal,
    canRequestFocus: hook.canRequestFocus,
    descendantsAreFocusable: hook.descendantsAreFocusable,
    descendantsAreTraversable: hook.descendantsAreTraversable,
  );

  @override
  void didUpdateHook(_FocusNodeHook oldHook) {
    _focusNode
      ..debugLabel = hook.debugLabel
      ..skipTraversal = hook.skipTraversal
      ..canRequestFocus = hook.canRequestFocus
      ..descendantsAreFocusable = hook.descendantsAreFocusable
      ..descendantsAreTraversable = hook.descendantsAreTraversable
      ..onKeyEvent = hook.onKeyEvent;
  }

  @override
  FocusNode build(BuildContext context) => _focusNode;

  @override
  void dispose() => _focusNode.dispose();

  @override
  String get debugLabel => 'useFocusNode';
}
