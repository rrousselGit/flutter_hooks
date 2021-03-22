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
  mobx.ReactiveContext? context,
  int? timeout,
  ErrorListener? onError,
}) {
  use(_WhenHook(
    predicate,
    effect,
    name: name,
    context: context,
    timeout: timeout,
    onError: onError,
  ));
}

class _WhenHook extends Hook<void> {
  const _WhenHook(
    this.predicate,
    this.effect, {
    this.name,
    this.context,
    this.timeout,
    this.onError,
  });

  static _When when = mobx.when;

  final Predicate predicate;
  final Effect effect;
  final String? name;
  final mobx.ReactiveContext? context;
  final int? timeout;
  final ErrorListener? onError;

  @override
  _WhenHookState createState() => _WhenHookState();
}

class _WhenHookState extends HookState<void, _WhenHook> {
  late mobx.ReactionDisposer disposer;

  @override
  void initHook() {
    disposer = _WhenHook.when(
      hook.predicate,
      hook.effect,
      name: hook.name,
      context: hook.context ?? mobx.mainContext,
      timeout: hook.timeout,
      onError: hook.onError,
    );
  }

  @override
  void build(BuildContext context) {}

  @override
  void dispose() {
    disposer();
  }
}
