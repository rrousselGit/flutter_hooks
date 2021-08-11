part of 'hooks.dart';

/// A callback to call when the app lifecycle changes.
typedef LifecycleCallback = FutureOr<void> Function(AppLifecycleState state);

class _AppLifecycleHook extends Hook<AppLifecycleState?> {
  const _AppLifecycleHook({
    List<Object>? keys,
    this.onInactive,
    this.onDetached,
    this.onPaused,
    this.onResumed,
    this.onStateChanged,
  }) : super(keys: keys);

  final LifecycleCallback? onResumed;
  final LifecycleCallback? onPaused;
  final LifecycleCallback? onDetached;
  final LifecycleCallback? onInactive;
  final LifecycleCallback? onStateChanged;

  @override
  __AppLifecycleStateState createState() => __AppLifecycleStateState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        ObjectFlagProperty<LifecycleCallback?>.has('onResumed', onResumed));
    properties
        .add(ObjectFlagProperty<LifecycleCallback?>.has('onPaused', onPaused));
    properties.add(
        ObjectFlagProperty<LifecycleCallback?>.has('onDetached', onDetached));
    properties.add(
        ObjectFlagProperty<LifecycleCallback?>.has('onInactive', onInactive));
  }
}

class __AppLifecycleStateState
    extends HookState<AppLifecycleState?, _AppLifecycleHook>
    with
        // ignore: prefer_mixin
        WidgetsBindingObserver {
  AppLifecycleState? _state;

  @override
  void initHook() {
    super.initHook();
    _state = WidgetsBinding.instance!.lifecycleState;
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  AppLifecycleState? build(BuildContext context) {
    return _state;
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance!.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    hook.onStateChanged?.call(state);
    switch (state) {
      case AppLifecycleState.resumed:
        hook.onResumed?.call(state);
        break;
      case AppLifecycleState.inactive:
        hook.onInactive?.call(state);
        break;
      case AppLifecycleState.paused:
        hook.onPaused?.call(state);
        break;
      case AppLifecycleState.detached:
        hook.onDetached?.call(state);
        break;
    }
    setState(() {
      _state = state;
    });
  }
}

/// Returns the current [AppLifecycleState] value.
///
/// This adds a listener to rebuild the widget when the value changes.
///
/// ## State change callbacks:
///
/// These are the accepted callbacks. All of them are run before the state update.
///
/// Note that these callbacks are added for convenience.
///
/// * **onResumed**: Called when the state changes to [AppLifecycleState.resumed].
/// * **onPaused**: Called when the state changes to [AppLifecycleState.paused].
/// * **onInactive**: Called when the state changes to [AppLifecycleState.inactive].
/// * **onDetached**: Called when the state changes to [AppLifecycleState.detached]. This might not be called.
/// * **onStateChanged**: Called for every change.
AppLifecycleState? useAppLifecycleState({
  List<Object>? keys,
  LifecycleCallback? onResumed,
  LifecycleCallback? onPaused,
  LifecycleCallback? onInactive,
  LifecycleCallback? onDetached,
  LifecycleCallback? onStateChanged,
}) {
  return use(_AppLifecycleHook(
    keys: keys,
    onDetached: onDetached,
    onInactive: onInactive,
    onPaused: onPaused,
    onResumed: onResumed,
    onStateChanged: onStateChanged,
  ));
}
