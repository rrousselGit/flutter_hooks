// ignore_for_file: omit_local_variable_types
import 'package:flutter/material.dart';
import 'package:flutter_hooks_gallery/use_effect.dart';
import 'package:flutter_hooks_gallery/use_state.dart';
import 'package:flutter_hooks_gallery/use_stream.dart';

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
            (context) => const UseStateExample(),
          ),
          _GalleryItem(
            'useStream',
            (context) {
              return UseStreamExample(
                stream: Stream.periodic(Duration(seconds: 1), (i) => i + 1),
              );
            },
          ),
          _GalleryItem(
            'useEffect',
            (context) {
              return const UseEffectExample();
            },
          ),
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
