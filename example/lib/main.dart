import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:localstorage/localstorage.dart';

void main() => runApp(_MyApp());

class _MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: _Counter(),
    );
  }
}

class _Counter extends HookWidget {
  const _Counter({Key key}) : super(key: key);

  @override
  Widget build(HookContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter app'),
      ),
      body: Center(
        child: Counter(),
      ),
    );
  }
}

void useEffect(HookContext context, VoidCallback effect(), [List parameters]) {
  return context.use(_EffectHook(effect, parameters));
}

final LocalStorage storage = LocalStorage('my_app');

StreamController<int> useLocalStorageInt(HookContext context, String key,
    {int defaultValue = 0}) {
  final controller = context.use(const StreamStateHook<int>());

  // we define a callback that will be called on first build
  // and whenever the controller/key change
  useEffect(context, () {
    // We listen to the data and push new values to local storage
    final sub = controller.stream.listen((data) async {
      await storage.ready;
      storage.setItem(key, data);
    });
    // Unsubscribe when the widget is disposed
    // or on controller/key change
    return sub.cancel;
  }, [controller, key]);

  // a callback that will be called only on the first build
  useEffect(context, () {
    storage.ready.then((ready) {
      if (ready) {
        int valueFromStorage = storage.getItem(key);
        controller.add(valueFromStorage ?? defaultValue);
      } else {
        controller
            .addError(DeferredLoadException('local storage failed to load'));
      }
    });
  }, const []);

  return controller;
}

class Counter extends HookWidget {
  @override
  Widget build(HookContext context) {
    StreamController<int> countController = useLocalStorageInt(context, 'foo');
    AsyncSnapshot<int> count = context.useStream(countController.stream);

    // Currently loading value from local storage, or there's an error
    if (!count.hasData) {
      return const CircularProgressIndicator();
    }

    return GestureDetector(
      onTap: () => countController.add(count.data + 1),
      child: Text('You tapped me ${count.data} times'),
    );
  }
}

class StreamStateHook<T> extends Hook<StreamController<T>> {
  const StreamStateHook();

  @override
  StreamStateHookState<T> createState() => StreamStateHookState<T>();
}

class StreamStateHookState<T>
    extends HookState<StreamController<T>, StreamStateHook<T>> {
  StreamController<T> _controller;

  @override
  void initHook() {
    super.initHook();
    _controller = StreamController.broadcast();
  }

  @override
  StreamController<T> build(HookContext context) {
    return _controller;
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}

class _EffectHook extends Hook<void> {
  final VoidCallback Function() effect;
  final List parameters;

  const _EffectHook(this.effect, [this.parameters]) : assert(effect != null);

  @override
  _EffectHookState createState() => _EffectHookState();
}

class _EffectHookState extends HookState<void, _EffectHook> {
  VoidCallback disposer;

  @override
  void initHook() {
    super.initHook();
    disposer = hook.effect();
  }

  @override
  void didUpdateHook(_EffectHook oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.parameters != oldHook.parameters &&
        (hook.parameters.length != oldHook.parameters.length ||
            _hasDiffWith(oldHook.parameters))) {
      if (disposer != null) {
        disposer();
      }
      disposer = hook.effect();
    }
  }

  bool _hasDiffWith(List parameters) {
    for (var i = 0; i < parameters.length; i++) {
      if (parameters[i] != hook.parameters[i]) {
        return true;
      }
    }
    return false;
  }

  @override
  void build(HookContext context) {}

  @override
  void dispose() {
    if (disposer != null) {
      disposer();
    }
    super.dispose();
  }
}
