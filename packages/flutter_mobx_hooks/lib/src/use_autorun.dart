import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobx/mobx.dart';

/// error handler
typedef ErrorHandler = void Function(Object, Reaction);

/// reaction handler
typedef ReactionHandler = void Function(Reaction);

/// Hook usage of mobx autorun function to run [fn] when reactive context changes
void useAutorun(
  ReactionHandler fn, {
  String? name,
  int? delay,
  ErrorHandler? onError,
}) {
  use(_AutorunHook(
    fn,
    name: name,
    delay: delay,
    onError: onError,
  ));
}

class _AutorunHook extends Hook<void> {
  const _AutorunHook(
    this.fn, {
    this.onError,
    this.delay,
    this.name,
  });

  static ReactionDisposer Function(
    Function(Reaction) fn, {
    String? name,
    int? delay,
    ReactiveContext? context,
    void Function(Object, Reaction)? onError,
  }) run = autorun;

  final ReactionHandler fn;
  final ErrorHandler? onError;
  final int? delay;
  final String? name;

  @override
  _AutorunHookState createState() => _AutorunHookState();
}

class _AutorunHookState extends HookState<void, _AutorunHook> {
  late ReactionDisposer _disposer;

  @override
  void initHook() {
    _run();
  }

  void _run() {
    _disposer = _AutorunHook.run(
      hook.fn,
      onError: hook.onError,
      delay: hook.delay,
      name: hook.name,
    );
  }

  @override
  void didUpdateHook(_AutorunHook oldHook) {
    if (oldHook.fn != hook.fn) {
      _disposer();
      _run();
    }
  }

  @override
  void build(BuildContext context) {}

  @override
  void dispose() {
    _disposer();
  }
}
