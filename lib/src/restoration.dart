part of 'hooks.dart';

/// Widget which behaves like [RestorationScope] but additional enables the use
/// of [useRestorationProperty] in its children.
class HookRestorationScope extends StatefulWidget {
  /// Creates a [HookRestorationScope].
  ///
  /// Providing null as the [restorationId] turns off state restoration for
  /// the [child] and its descendants.
  ///
  /// The [child] must not be null.
  const HookRestorationScope({
    Key key,
    @required this.restorationId,
    @required this.child,
  })  : assert(child != null, 'child cannot be null.'),
        super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// The restoration ID used by this widget to obtain a child bucket from the
  /// surrounding [RestorationScope].
  ///
  /// The child bucket obtained from the surrounding scope is made available to
  /// descendant widgets via [RestorationScope.of].
  ///
  /// If this is null, [RestorationScope.of] invoked by descendants will return
  /// null which effectively turns off state restoration for this subtree.
  final String restorationId;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('restorationId', restorationId));
  }

  @override
  _HookRestorationScopeState createState() => _HookRestorationScopeState();
}

/// A [State] implementation which allows registration of [RestorableProperty]s
/// from a [HookState].
class _HookRestorationScopeState extends State<HookRestorationScope>
    with RestorationMixin {
  /// Currently registered [RestorableProperty]s by restorationId.
  final _properties = <String, RestorableProperty<void>>{};

  @override
  Widget build(BuildContext context) {
    return _HookRestorationScopeMarker(
      scope: this,
      child: UnmanagedRestorationScope(
        bucket: bucket,
        child: widget.child,
      ),
    );
  }

  @override
  String get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket oldBucket) {
    for (final entry in _properties.entries) {
      registerForRestoration(entry.value, entry.key);
    }
  }

  /// Called from a hook to register its property with this scope.
  void registerProperty(
    String restorationId,
    RestorableProperty<void> property,
  ) {
    _properties[restorationId] = property;
    registerForRestoration(property, restorationId);
  }

  /// Called from a hook to unregister its property from this scope.
  void unRegisterProperty(String restorationId) {
    unregisterFromRestoration(_properties[restorationId]);
    _properties.remove(restorationId);
  }
}

/// [InheritedWidget] to make [_HookRestorationScopeState] available to
/// [useRestorationProperty].
class _HookRestorationScopeMarker extends InheritedWidget {
  const _HookRestorationScopeMarker({
    @required this.scope,
    @required Widget child,
  })  : assert(child != null, 'child cannot be null.'),
        super(child: child);

  // ignore: diagnostic_describe_all_properties
  final _HookRestorationScopeState scope;

  @override
  bool updateShouldNotify(_HookRestorationScopeMarker old) =>
      scope != old.scope;
}

class _RestorablePropertyHook<T extends RestorableProperty<void>>
    extends Hook<T> {
  const _RestorablePropertyHook({
    @required this.scope,
    @required this.restorationId,
    @required this.property,
  });

  /// The state of the [HookRestorationScope] this hook should register
  /// [property] with.
  final _HookRestorationScopeState scope;

  /// The `restorationId` to register [property] with.
  final String restorationId;

  /// The [RestorableProperty] this hook manages.
  final T property;

  @override
  _RestorablePropertyHookState<T> createState() =>
      _RestorablePropertyHookState();
}

class _RestorablePropertyHookState<T extends RestorableProperty<void>>
    extends HookState<T, _RestorablePropertyHook<T>> {
  T property;

  @override
  void initHook() {
    super.initHook();
    property = hook.property;
    hook.scope.registerProperty(hook.restorationId, property);
  }

  @override
  T build(BuildContext context) => property;

  @override
  void didUpdateHook(_RestorablePropertyHook<T> oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.scope != oldHook.scope ||
        hook.restorationId != oldHook.restorationId) {
      oldHook.scope.unRegisterProperty(oldHook.restorationId);
      hook.scope.registerProperty(hook.restorationId, hook.property);
    }
  }

  @override
  bool shouldRebuild() => false;

  @override
  void dispose() {
    super.dispose();
    property.dispose();
  }
}

/// Registers [property] with the nearest [HookRestorationScope] under
/// [restorationId].
///
/// Only the value passed for [property] when [useRestorationProperty] is called
/// for the first time is used. Every time [useRestorationProperty] is called
/// the same initial value is returned.
///
/// By default the registered property is listened to and triggers a rebuild of
/// the surrounding widget when changed. Setting [listen] to `false` disables
/// this behaviour.
///
/// ## Example
///
/// ```dart
/// class RestorablePropertyExample extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(
///         title: const Text('useRestorationProperty example'),
///       ),
///       body: RootRestorationScope(
///         restorationId: 'root',
///         child: HookRestorationScope(
///           restorationId: 'hooks',
///           child: HookBuilder(
///             builder: (context) {
///               final count = useRestorationProperty('count', RestorableInt(0));
///               return Center(
///                 child: ElevatedButton(
///                   onPressed: () => count.value += 1,
///                   child: Text('${count.value} clicks'),
///                 ),
///               );
///             },
///           ),
///         ),
///       ),
///     );
///   }
/// }
/// ```
///
/// See also:
///
///   * [HookRestorationScope] which is equivalent to [RestorationScope] but
///     additionally enables the usage of this hook in its children.
///   * [RestorableProperty] which is a wrapper for a value which should be
///     persisted and restored as part of Flutters restoration system.
T useRestorationProperty<T extends RestorableProperty<void>>(
  String restorationId,
  T property, {
  bool listen = true,
}) {
  assert(restorationId != null, 'restorationId cannot be null.');
  assert(property != null, 'property cannot be null.');
  assert(listen != null, 'listenToValue cannot be null.');

  final scope = useContext()
      .dependOnInheritedWidgetOfExactType<_HookRestorationScopeMarker>()
      ?.scope;

  assert(
    scope != null,
    'To use useRestorationProperty make sure a HookRestorationScope is '
    'available from where useRestorationProperty is called.',
  );

  final result = use(_RestorablePropertyHook(
    restorationId: restorationId,
    property: property,
    scope: scope,
  ));

  if (listen) {
    useListenable(result);
  }

  return result;
}
