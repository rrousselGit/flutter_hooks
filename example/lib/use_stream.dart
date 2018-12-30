import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class UseStreamExample extends StatelessWidget {
  final Stream<int> stream;

  const UseStreamExample({Key key, @required this.stream}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('useStream example'),
      ),
      body: Center(
        child: HookBuilder(
          builder: (context) {
            final snapshot = useStream(stream);

            return Text(
              '${snapshot.data ?? 0}',
              style: const TextStyle(fontSize: 36),
            );
          },
        ),
      ),
    );
  }
}
