import 'package:flutter/material.dart';
import 'package:flutter_hooks/hook.dart';
import 'package:rxdart/rxdart.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Flutter Demo', home: Home());
  }
}

Observable<int> controller =
    Observable.periodic(const Duration(seconds: 1), (i) => i);
Observable<int> controller2 =
    Observable.periodic(const Duration(seconds: 2), (i) => i);

class Home extends HookWidget {
  @override
  Widget build(HookContext context) {
    final v1 = context.useStream(controller);
    final v2 = context.useStream(controller2);
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: <Widget>[
          Text(v1.data?.toString() ?? "0"),
          Text(v2.data?.toString() ?? "0"),
        ],
      ),
    );
  }
}
