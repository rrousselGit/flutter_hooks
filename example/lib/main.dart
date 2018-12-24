// ignore_for_file: omit_local_variable_types
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
    StreamController<int> countController =
        _useLocalStorageInt(context, 'counter');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter app'),
      ),
      body: Center(
        child: HookBuilder(
          builder: (context) {
            AsyncSnapshot<int> count =
                context.useStream(countController.stream);

            return !count.hasData
                // Currently loading value from local storage, or there's an error
                ? const CircularProgressIndicator()
                : GestureDetector(
                    onTap: () => countController.add(count.data + 1),
                    child: Text('You tapped me ${count.data} times'),
                  );
          },
        ),
      ),
    );
  }
}

final LocalStorage _storage = LocalStorage('my_app');

StreamController<int> _useLocalStorageInt(
  HookContext context,
  String key, {
  int defaultValue = 0,
}) {
  final controller = context.useStreamController<int>();

  context
    // We define a callback that will be called on first build
    // and whenever the controller/key change
    ..useEffect(() {
      // We listen to the data and push new values to local storage
      final sub = controller.stream.listen((data) async {
        await _storage.ready;
        _storage.setItem(key, data);
      });
      // Unsubscribe when the widget is disposed
      // or on controller/key change
      return sub.cancel;
    }, [controller, key])
    // We load the initial value
    ..useEffect(() {
      _storage.ready.then((ready) {
        if (ready) {
          int valueFromStorage = _storage.getItem(key);
          controller.add(valueFromStorage ?? defaultValue);
        } else {
          controller
              .addError(DeferredLoadException('local storage failed to load'));
        }
      });
      // ensure the callback is called only on first build
    }, [controller, key]);

  return controller;
}
