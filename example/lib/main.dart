// ignore_for_file: omit_local_variable_types
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        child: HookBuilder(
          builder: (context) {
            // TODO: moving this to the root, and removing foo throws an assertion fail
            StreamController<int> countController =
                _useLocalStorageInt(context, 'counter');
            AsyncSnapshot<int> count =
                context.useStream(countController.stream);

            final foo = context.useMemoized(() {
              return count.data;
            }, <dynamic>[(count.data ?? 0) % 4 == 0]);

            print('${foo ?? -1}  ${(count.data ?? 0) / 4} ');
            return !count.hasData
                // Currently loading value from local storage, or there's an error
                ? const CircularProgressIndicator()
                : GestureDetector(
                    onTap: () => countController.add(count.data + 1),
                    child: Text(
                        'You tapped me ${count.data} times memoized $foo '),
                  );
          },
        ),
      ),
    );
  }
}

StreamController<int> _useLocalStorageInt(
  HookContext context,
  String key, {
  int defaultValue = 0,
}) {
  final controller = context.useStreamController<int>(keys: <dynamic>[key]);

  context
    // We define a callback that will be called on first build
    // and whenever the controller/key change
    ..useEffect(() {
      // We listen to the data and push new values to local storage
      final sub = controller.stream.listen((data) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(key, data);
      });
      // Unsubscribe when the widget is disposed
      // or on controller/key change
      return sub.cancel;
    }, <dynamic>[controller, key])
    // We load the initial value
    ..useEffect(() {
      SharedPreferences.getInstance().then((prefs) async {
        int valueFromStorage = prefs.getInt(key);
        controller.add(valueFromStorage ?? defaultValue);
      }).catchError(controller.addError);
      // ensure the callback is called only on first build
    }, <dynamic>[controller, key]);

  return controller;
}
