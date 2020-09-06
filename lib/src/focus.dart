part of 'hooks.dart';

/// Creates and dispose of a [FocusNode].
///
/// See also:
/// - [FocusNode]
FocusNode useFocusNode({
  String debugLabel,
  FocusOnKeyCallback onKey,
  bool skipTraversal = false,
  bool canRequestFocus = true,
  bool descendantsAreFocusable = true,
}) =>
    use(_FocusNodeHook(
      debugLabel: debugLabel,
      onKey: onKey,
      skipTraversal: skipTraversal,
      canRequestFocus: canRequestFocus,
      descendantsAreFocusable: descendantsAreFocusable,
    ));

class _FocusNodeHook extends Hook<FocusNode> {
  const _FocusNodeHook({
    this.debugLabel,
    this.onKey,
    this.skipTraversal,
    this.canRequestFocus,
    this.descendantsAreFocusable,
  });

  final String debugLabel;
  final FocusOnKeyCallback onKey;
  final bool skipTraversal;
  final bool canRequestFocus;
  final bool descendantsAreFocusable;

  @override
  _FocusNodeHookState createState() {
    return _FocusNodeHookState();
  }
}

class _FocusNodeHookState extends HookState<FocusNode, _FocusNodeHook> {
  FocusNode _focusNode;

  @override
  void initHook() {
    _focusNode = FocusNode(
      debugLabel: hook.debugLabel,
      onKey: hook.onKey,
      skipTraversal: hook.skipTraversal,
      canRequestFocus: hook.canRequestFocus,
      descendantsAreFocusable: hook.descendantsAreFocusable,
    );
  }

  @override
  void didUpdateHook(_FocusNodeHook oldHook) {
    _focusNode
      ..debugLabel = hook.debugLabel
      ..skipTraversal = hook.skipTraversal
      ..canRequestFocus = hook.canRequestFocus
      ..descendantsAreFocusable = hook.descendantsAreFocusable;
  }

  @override
  FocusNode build(BuildContext context) => _focusNode;

  @override
  void dispose() => _focusNode?.dispose();

  @override
  String get debugLabel => 'useFocusNode';
}
