part of 'hooks.dart';

/// An alternative to [useListenable] for listening to a [Listenable], with the
/// added benefit of rebuilding the widget only if a certain value has changed.
///
/// [useListenableSelector] will return the result of the callback.
/// And whenever the listenable notify its listeners, the callback will be
/// re-executed.
/// Then, if the value returned has changed, the widget will rebuild. Otherwise,
/// the widget will ignore the [Listenable] update.
///
/// The following example uses [useListenableSelector] to listen to a
/// [TextEditingController], yet rebuild the widget only when the input changes
/// between empty and not empty.
/// Whereas if we used [useListenable], the widget would've rebuilt everytime
/// the user types a character.
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
      setState(() {
        _state = result;
      });
    }
  }

  @override
  void dispose() {
    hook.listenable.removeListener(_listener);
  }

  @override
  String get debugLabel => 'useListenableSelector<$R>';
}
