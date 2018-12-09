import 'package:flutter/material.dart';
import 'package:flutter_hooks/hook.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';

part 'main.g.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Flutter Demo', home: TestAnimation());
  }
}

final tween = ColorTween(
  begin: Colors.red,
  end: Colors.blue,
);

@widget
Widget testAnimation(HookContext context, {Color color}) {
  final controller =
      context.useAnimationController(duration: const Duration(seconds: 1));

  final colorTween =
      context.useValueChanged(color, (Color previous, Color next) {
            controller.forward(from: 0);
            return ColorTween(begin: previous, end: next).animate(controller);
          },) ??
          AlwaysStoppedAnimation(color);

  final currentColor = context.useAnimation(colorTween);
  return Container(color: currentColor);
}
