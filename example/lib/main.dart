// ignore_for_file: omit_local_variable_types
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_hooks_gallery/use_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(_GalleryApp());

class _GalleryItem {
  final String title;
  final WidgetBuilder builder;

  const _GalleryItem(this.title, this.builder);
}

class _GalleryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Hooks Gallery',
      home: _GalleryList(
        items: [
          _GalleryItem(
            'useState',
            (context) => UseStateExample(),
          )
        ],
      ),
    );
  }
}

class _GalleryList extends StatelessWidget {
  final List<_GalleryItem> items;

  const _GalleryList({Key key, @required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Hooks Gallery'),
      ),
      body: ListView(
        children: items.map((item) {
          return ListTile(
            title: Text(item.title),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: item.builder,
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

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
    final countController = _useLocalStorageInt(context, 'counter');
    final count = context.useStream(countController.stream);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter app'),
      ),
      body: Center(
        child: count.hasData
            ? GestureDetector(
                onTap: () => countController.add(count.data + 1),
                child: Text('You tapped me ${count.data} times'),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(key, data);
      });
      // Unsubscribe when the widget is disposed
      // or on controller/key change
      return sub.cancel;
    }, [controller, key])
    // We load the initial value
    ..useEffect(() {
      SharedPreferences.getInstance().then((prefs) async {
        int valueFromStorage = prefs.getInt(key);
        controller.add(valueFromStorage ?? defaultValue);
      }).catchError(controller.addError);
      // ensure the callback is called only on first build
    }, [controller, key]);

  return controller;
}
