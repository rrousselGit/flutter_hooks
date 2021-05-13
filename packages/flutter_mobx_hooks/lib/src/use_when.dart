import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobx/mobx.dart' as mobx;

// ignore: avoid_private_typedef_functions
typedef _When = mobx.ReactionDisposer Function(
  bool Function(mobx.Reaction) predicate,
  void Function() effect, {
  String? name,
  mobx.ReactiveContext? context,
  int? timeout,
  void Function(Object, mobx.Reaction)? onError,
});

/// predicate handler
typedef Predicate = bool Function(mobx.Reaction);

/// effect handler
typedef Effect = void Function();

/// error handler
typedef ErrorListener = void Function(Object, mobx.Reaction);

/// Hook usage of mobx when function to run [effect] when [predicate] is true
void useWhen(
  Predicate predicate,
  Effect effect, {
  String? name,
  int? timeout,
  ErrorListener? onError,
}) {
  use(_WhenHook(
    predicate,
    effect,
    name: name,
    timeout: timeout,
    onError: onError,
  ));
}

class _WhenHook extends Hook<void> {
  const _WhenHook(
    this.predicate,
    this.effect, {
    this.name,
    this.timeout,
    this.onError,
  });

  static _When when = mobx.when;

  final Predicate predicate;
  final Effect effect;
  final String? name;
  final int? timeout;
  final ErrorListener? onError;

  @override
  _WhenHookState createState() => _WhenHookState();
}

class _WhenHookState extends HookState<void, _WhenHook> {
  late mobx.ReactionDisposer _disposer;

  @override
  void initHook() {
    _createWhen();
  }

  void _createWhen() {
    _disposer = _WhenHook.when(
      hook.predicate,
      () => hook.effect(),
      name: hook.name,
      timeout: hook.timeout,
      onError: hook.onError,
    );
  }

  @override
  void didUpdateHook(_WhenHook oldHook) {
    if (oldHook.predicate != hook.predicate) {
      _disposer();
      _createWhen();
    }
  }

  @override
  void build(BuildContext context) {}

  @override
  void dispose() {
    _disposer();
  }
}