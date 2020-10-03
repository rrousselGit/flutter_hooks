part of 'hooks.dart';

abstract class _GestureRecognizerHook<G extends GestureRecognizer>
    extends Hook<G> {
  const _GestureRecognizerHook(List<Object> keys) : super(keys: keys);

  @override
  HookState<G, Hook<G>> createState() => _GestureRecognizerHookState<G>();

  G initRecognizer();
}

class _GestureRecognizerHookState<G extends GestureRecognizer>
    extends HookState<G, _GestureRecognizerHook<G>> {
  G recognizer;

  @override
  void initHook() => recognizer = hook.initRecognizer();

  @override
  G build(BuildContext context) => recognizer;

  @override
  void dispose() => recognizer?.dispose();

  @override
  String get debugLabel => 'use$G';
}

/// Creates and disposes a [TapGestureRecognizer].
///
/// See also:
/// - [TapGestureRecognizer]
TapGestureRecognizer useTapGestureRecognizer({
  Object debugOwner,
  List<Object> keys,
}) =>
    use(_TapGestureRecognizerHook(
      debugOwner: debugOwner,
      keys: keys,
    ));

class _TapGestureRecognizerHook
    extends _GestureRecognizerHook<TapGestureRecognizer> {
  const _TapGestureRecognizerHook({
    this.debugOwner,
    List<Object> keys,
  }) : super(keys);

  final Object debugOwner;

  @override
  TapGestureRecognizer initRecognizer() =>
      TapGestureRecognizer(debugOwner: debugOwner);
}
