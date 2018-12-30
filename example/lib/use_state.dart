import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Demonstrates the `useState` hook.
class UseStateExample extends HookWidget {
  const UseStateExample({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final counter = useState(0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('useState example'),
      ),
      body: Center(
        child: Text('Button tapped ${counter.value} times'),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => counter.value++,
      ),
    );
  }
}
