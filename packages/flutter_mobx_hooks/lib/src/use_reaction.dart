import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobx/mobx.dart';

/// error handler
typedef ErrorHandler = void Function(Object, Reaction);

/// reaction setup handler
typedef ReactionSetup<T> = T Function(Reaction);

/// Hook usage of mobx reaction function to run [effect] when [fn] changes
/// the result of [fn] is pass to [effect]
void useReaction<T>(ReactionSetup<T> fn, Function(T) effect,
    {String? name,
    int? delay,
    bool? fireImmediately,
    EqualityComparer<T>? equals,
    ErrorHandler? onError}) {
  use(
    _ReactionHook(
      fn,
      effect,
      name: name,
      delay: delay,
      fireImmediately: fireImmediately,
      equals: equals,
      onError: onError,
    ),
  );
}

class _ReactionHook<T> extends Hook<void> {
  const _ReactionHook(this.fn, this.effect,
      {this.name, this.delay, this.fireImmediately, this.equals, this.onError});

  final ReactionSetup<T> fn;
  final Function(T) effect;
  final String? name;
  final int? delay;
  final bool? fireImmediately;
  final EqualityComparer<T>? equals;
  final ErrorHandler? onError;

  @override
  _ReactionHookState<T> createState() => _ReactionHookState<T>();
}

class _ReactionHookState<T> extends HookState<void, _ReactionHook<T>> {
  late ReactionDisposer _disposer;

  void _createReaction() {
    _disposer = reaction<T>(
      hook.fn,
      (data) => hook.effect(data),
      equals: hook.equals,
      fireImmediately: hook.fireImmediately,
      name: hook.name,
      onError: hook.onError,
      delay: hook.delay,
    );
  }

  @override
  void didUpdateHook(_ReactionHook<T> oldHook) {
    if (oldHook.fn != hook.fn) {
      _disposer();
      _createReaction();
    }
  }

  @override
  void initHook() {
    _createReaction();
  }

  @override
  void build(BuildContext context) {}

  @override
  void dispose() {
    _disposer();
  }
}
