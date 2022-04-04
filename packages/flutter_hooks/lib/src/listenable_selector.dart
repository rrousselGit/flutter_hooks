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
  return use(_ListenableSelectorHook<R>(listenable, callback)).value;
}

class _ListenableSelectorHook<R> extends Hook<ValueNotifier<R>> {
  const _ListenableSelectorHook(this.listenable, this.callback);

  final Listenable listenable;
  final R Function() callback;

  @override
  _ListenableSelectorHookState<R> createState() =>
      _ListenableSelectorHookState<R>();
}

class _ListenableSelectorHookState<R>
    extends HookState<ValueNotifier<R>, _ListenableSelectorHook<R>> {
  late final ValueNotifier<R> _state = ValueNotifier<R>(hook.callback())
    ..addListener(() => setState(() {}));

  @override
  void initHook() {
    super.initHook();
    hook.listenable.addListener(_listener);
  }

  @override
  ValueNotifier<R> build(BuildContext context) => _state;

  void _listener() {
    _state.value = hook.callback();
  }

  @override
  void dispose() {
    hook.listenable.removeListener(_listener);
  }

  @override
  String get debugLabel => 'useListenableSelector<$R>';
}
