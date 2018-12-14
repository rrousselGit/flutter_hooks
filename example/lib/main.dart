import 'package:flutter/material.dart';
import 'package:flutter_hooks/hook.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';

part 'main.g.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: _Foo(),
    );
  }
}

@widget
Widget _testAnimation(HookContext context, {Color color}) {
  final controller =
      context.useAnimationController(duration: const Duration(seconds: 5));

  final colorTween = context.useValueChanged(
        color,
        (Color oldValue, Animation<Color> oldResult) {
          return ColorTween(
            begin: oldResult?.value ?? oldValue,
            end: color,
          ).animate(controller..forward(from: 0));
        },
      ) ??
      AlwaysStoppedAnimation(color);

  final currentColor = context.useAnimation(colorTween);
  return Container(color: currentColor);
}

@widget
Widget _foo(HookContext context) {
  final toggle = context.useState(initialData: false);
  final counter = context.useState(initialData: 0);

  return Scaffold(
    body: GestureDetector(
      onTap: () {
        toggle.value = !toggle.value;
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: _TestAnimation(
              color: toggle.value
                  ? const Color.fromARGB(255, 255, 0, 0)
                  : const Color.fromARGB(255, 0, 0, 255),
            ),
          ),
          Center(
            child: Text(counter.value.toString()),
          )
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => counter.value++,
      child: const Icon(Icons.plus_one),
    ),
  );
}
