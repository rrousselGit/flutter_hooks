import 'package:flutter/material.dart';
import 'package:flutter_hooks/hook.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'main.g.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Flutter Demo', home: _Home());
  }
}

@widget
Widget _home(HookContext context) {
  final controller =
      context.useAnimationController(duration: const Duration(seconds: 2));
  final controller2 =
      context.useAnimationController(duration: const Duration(seconds: 1));
  return Scaffold(
    appBar: AppBar(),
    body: Row(
      children: <Widget>[
        _AnimatedText(controller),
        _AnimatedText(controller2),
      ],
    ),
  );
}

@widget
Column _animatedText(AnimationController controller) {
  return Column(
    children: <Widget>[
      AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Text(controller.value.toString());
        },
      ),
      RaisedButton(
        onPressed: () => controller.forward(from: 0),
      )
    ],
  );
}
