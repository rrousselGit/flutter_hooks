import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Demonstrates the `useState` hook.
class UseStateExample extends HookWidget {
  @override
  Widget build(HookContext context) {
    // First, create a stateful
    final counter = context.useState(0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('useState example'),
      ),
      body: Center(
        child: Text('Button tapped ${counter.value} times'),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => counter.value--,
      ),
    );
  }
}
