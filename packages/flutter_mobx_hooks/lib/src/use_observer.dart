import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobx/mobx.dart';
// ignore: implementation_imports
import 'package:mobx/src/core.dart' show ReactionImpl;

/// Hook usage of mobx observer, it will observe for any changes and rebuild
/// upon them. It replace the Observer widget of mobx
void useObserver() {
  use(const _ObserverHook());
}

class _ObserverHook extends Hook<void> {
  const _ObserverHook();

  @override
  HookState<void, Hook> createState() => _ObserverHookState();
}

class _ObserverHookState extends HookState<void, _ObserverHook> {
  late ReactionImpl _reaction;
  Derivation? _prevDerivation;

  @override
  void initHook() {
    super.initHook();

    _reaction = _createReaction();
    setDidBuildListener(() {
      _reaction.endTracking(_prevDerivation);
      _prevDerivation = null;
    });
  }

  ReactionImpl _createReaction() {
    final name = mainContext.nameFor('ObserverHook-Reaction');
    return ReactionImpl(mainContext, onInvalidate, name: name);
  }

  void onInvalidate() => setState(_noOp);

  static void _noOp() {}

  @override
  void build(BuildContext context) {
    _prevDerivation = _reaction.startTracking();
  }

  @override
  void dispose() {
    _reaction.dispose();

    super.dispose();
  }
}
