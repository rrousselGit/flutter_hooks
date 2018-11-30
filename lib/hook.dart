import 'dart:async';

import 'package:flutter/widgets.dart';

@immutable
abstract class Hook {
  HookState createHookState();
}

class HookState<T extends Hook> {
  Element _element;
  BuildContext get context => _element;
  T _hook;
  T get hook => _hook;
  void initHook() {}
  void dispose() {}
  void didUpdateWidget(covariant Widget widget) {}
  void didUpdateHook(covariant Hook hook) {}
  void setState(VoidCallback callback) {
    callback();
    _element.markNeedsBuild();
  }
}

class _StreamHook<T> extends Hook {
  final Stream<T> stream;
  final T initialData;
  _StreamHook({this.stream, this.initialData});
  @override
  HookState<Hook> createHookState() => _StreamHookState<T>();
}

class _StreamHookState<T> extends HookState<_StreamHook<T>> {
  StreamSubscription<T> subscription;
  AsyncSnapshot<T> snapshot;
  @override
  void initHook() {
    super.initHook();
    snapshot = hook.stream == null
        ? AsyncSnapshot<T>.nothing()
        : AsyncSnapshot<T>.withData(ConnectionState.waiting, hook.initialData);
    subscription = hook.stream.listen(onData, onDone: onDone, onError: onError);
  }

  void onData(T event) {
    print('on data $event');
    setState(() {
      snapshot = AsyncSnapshot<T>.withData(ConnectionState.active, event);
    });
  }

  void onDone() {
    setState(() {
      snapshot = AsyncSnapshot<T>.withData(ConnectionState.done, snapshot.data);
    });
  }

  void onError(Object error) {
    setState(() {
      snapshot = AsyncSnapshot<T>.withError(ConnectionState.active, error);
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }
}

class HookElement extends StatelessElement implements HookContext {
  int _hooksIndex;
  List<HookState> _hooks;

  HookElement(HookWidget widget) : super(widget);

  @override
  HookWidget get widget => super.widget;

  HookState useHook(Hook hook) {
    final int hooksIndex = _hooksIndex;
    _hooksIndex++;
    _hooks ??= [];

    HookState state;
    if (hooksIndex >= _hooks.length) {
      state = hook.createHookState()
        .._element = this
        .._hook = hook
        ..initHook();
      _hooks.add(state);
    } else {
      state = _hooks[hooksIndex];
      if (!identical(state._hook, hook)) {
        final Hook previousHook = state._hook;
        state._hook = hook;
        state.didUpdateHook(previousHook);
      }
    }
    return state;
  }

  AsyncSnapshot<T> useStream<T>(Stream<T> stream, {T initialData}) {
    final _StreamHookState<T> state =
        useHook(_StreamHook<T>(stream: stream, initialData: initialData));
    return state.snapshot;
  }

  @override
  void performRebuild() {
    _hooksIndex = 0;
    super.performRebuild();
  }
}

abstract class HookWidget extends StatelessWidget {
  @override
  HookElement createElement() => HookElement(this);

  @protected
  Widget build(covariant HookContext context);
}

abstract class HookContext extends BuildContext {
  HookState useHook(Hook hook);
  AsyncSnapshot<T> useStream<T>(Stream<T> stream, {T initialData});
}
