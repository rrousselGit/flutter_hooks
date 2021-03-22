import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobx/mobx.dart';
// ignore: implementation_imports
import 'package:mobx/src/core.dart' show ReactionImpl;

/// Hook usage of mobx observer, it will observe for any changes and rebuild
/// upon them. It replace the Observer widget of mobx
void useObserver({ReactiveContext? context}) {
  final observer =
      context == null ? const _ObserverHook() : _ObserverHook(context: context);
  use(observer);
}

class _ObserverHook extends Hook<void> {
  const _ObserverHook({ReactiveContext? context}) : _context = context;

  // TODO(rrousselGit): scoped constructor

  final ReactiveContext? _context;
  ReactiveContext get context => _context ?? mainContext;

  @override
  HookState<void, Hook> createState() => _ObserverHookState();
}

class _ObserverHookState extends HookState<void, _ObserverHook> {
  late ReactionImpl reaction;
  Derivation? prevDerivation;

  @override
  void initHook() {
    super.initHook();

    reaction = createReaction();
    setDidBuildListener(() {
      reaction.endTracking(prevDerivation);
      prevDerivation = null;
    });
  }

  @override
  void didUpdateHook(_ObserverHook oldHook) {
    if (hook.context != oldHook.context) {
      reaction.dispose();
      reaction = createReaction();
    }
  }

  ReactionImpl createReaction() {
    final name = hook.context.nameFor('ObserverHook-Reaction');
    return ReactionImpl(hook.context, onInvalidate, name: name);
  }

  void onInvalidate() => setState(_noOp);

  static void _noOp() {}

  @override
  void build(BuildContext context) {
    prevDerivation = reaction.startTracking();
  }

  @override
  void dispose() {
    reaction.dispose();

    super.dispose();
  }
}
