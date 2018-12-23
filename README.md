[![Build Status](https://travis-ci.org/rrousselGit/flutter_hooks.svg?branch=master)](https://travis-ci.org/rrousselGit/flutter_hooks) [![codecov](https://codecov.io/gh/rrousselGit/flutter_hooks/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/flutter_hooks)

[![pub package](https://img.shields.io/pub/v/flutter_hooks.svg)](https://pub.dartlang.org/packages/flutter_hooks)

<img src="flutter-hook.svg" width="200">

# Flutter Hooks

A flutter implementation of React hooks: https://medium.com/@dan_abramov/making-sense-of-react-hooks-fdbde8803889

## What are hooks?

Hooks are a new kind of object that manages a `Widget` life-cycles. They exists for one reason: increase the code sharing _between_ widgets and as a complete replacement for `StatefulWidget`.

### The StatefulWidget issue

`StatefulWidget` suffer from a big problem: it is very difficult reuse the logic of say `initState` or `dispose`. An obvious example is `AnimationController`:

```dart
class Example extends StatefulWidget {
  @override
  _ExampleState createState() => _ExampleState();
}

class _ExampleState extends State<Example>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

All widgets that desired to use an `AnimationController` will have to copy-paste the `initState`/`dispose`, which is of course undesired.

Dart mixins can partially solve this issue, but they are the source of another problem: type conflicts. If two mixins defines the same variable, the behavior may vary from a compilation fail to a totally unexpected behavior.

### The Hook solution

Hooks are designed so that we can reuse the `initState`/`dispose` logic shown before between widgets. But without the potential issues of a mixin.

_Hooks are independents and can be reused as many times as desired._

This means that with hooks, the equivalent of the previous code is:

```dart
class Example extends HookWidget {
  @override
  Widget build(HookContext context) {
    final controller = context.useAnimationController(
      duration: const Duration(seconds: 1),
    );
    return Container();
  }
}
```
