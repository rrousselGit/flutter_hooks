import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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
    final counter = context.useState(initialData: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter app'),
      ),
      body: Center(
        child: Text(counter.value.toString()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => counter.value++,
      ),
    );
  }
}
