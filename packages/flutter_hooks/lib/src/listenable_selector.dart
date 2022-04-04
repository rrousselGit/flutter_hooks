part of 'hooks.dart';

/// Subscribes to a [Listenable]
/// and execute callback() whenever [Listenable] update.
/// Subscribe to a Listenable.
/// When [Listenable] update execute callback(). it result value is return value.
/// It don't rebuild the widget unless that result of callback() does not changed. so an unnecessary rebuild not occur, performance is better.
///
/// ```dart
/// class Example extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///    final listenable = useTextEditingController();
///    final bool textIsEmpty =
///         useListenableSelector(listenable, () => listenable.text.isEmpty);
///    return Column(
///       children: [
///         TextField(controller: listenable),
///         ElevatedButton(
///             // if textIsEmpty is false,　the button is disabled.
///             onPressed: textIsEmpty ? null : () => print("Pressed!"),
///             child: Text("Button")),
///       ],
///     );
///   }
/// }
/// ```
R useListenableSelector<R>(Listenable listenable, R Function() callback) {
  return use(_ListenableSelectorHook<R>(listenable, callback));
}

class _ListenableSelectorHook<R> extends Hook<R> {
  const _ListenableSelectorHook(this.listenable, this.callback);

  final Listenable listenable;
  final R Function() callback;

  @override
  _ListenableSelectorHookState<R> createState() =>
      _ListenableSelectorHookState<R>();
}

class _ListenableSelectorHookState<R>
    extends HookState<R, _ListenableSelectorHook<R>> {
  late R _state = hook.callback();

  @override
  void initHook() {
    super.initHook();
    hook.listenable.addListener(_listener);
  }

  @override
  R build(BuildContext context) => _state;

  void _listener() {
    final result = hook.callback();
    if (_state != result) {
      _state = result;
      setState(() {});
    }
  }

  @override
  void dispose() {
    hook.listenable.removeListener(_listener);
  }

  @override
  String get debugLabel => 'useListenableSelector<$R>';
}
