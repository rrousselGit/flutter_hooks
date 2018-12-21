[![Build Status](https://travis-ci.org/rrousselGit/flutter_hooks.svg?branch=master)](https://travis-ci.org/rrousselGit/flutter_hooks) [![codecov](https://codecov.io/gh/rrousselGit/flutter_hooks/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/flutter_hooks)

[![pub package](https://img.shields.io/pub/v/flutter_hooks.svg)](https://pub.dartlang.org/packages/flutter_hooks)

![alt text](https://raw.githubusercontent.com/rrousselGit/flutter_hooks/master/hooks.png)

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

`useAnimationController` is what we call a _Hook_. Hooks pretty similar to `State` and mixins, with some important differences:

- A `HookWidget` can use as many hooks as desired. Not just one.
- The same Hook can be used multiple times too, as opposed to mixins.
- Hooks are entirely independent from each others and from the widget. Implying that they are composable, reusable, et shareable.

For example using hooks a naive counter widget would be the following:

```dart
class Counter extends HookWidget {
  const Counter({Key key}) : super(key: key);

  @override
  Widget build(HookContext context) {
    final counter = context.useState(initialData: 0);

    return Scaffold(
      body: Center(
        child: Text(counter.value.toString()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => counter.value++,
      ),
    );
  }
}
```

Notice how the widget is written in a single class, with no need to call `setState` or declare a field on the class.

## The principle

Hooks, similarily to `State`, are stored on the `Element`. But instead of having one `State`, the `Element` stores a `List<Hook>`. To then obtain the content of a `Hook`, one must call `HookContext.use`.

The hook returned is based on the number of times the `use` method has been called. So that the first call returns the first hook; the second call returns the second hook, the third returns the third hook, ...

A naive implementation could be the following:

```dart
class HookElement extends Element {
  List<HookState> _hooks;
  int _hookIndex;

  T use<T>(Hook<T> hook) => _hooks[_hookIndex++].build(this);

  @override
  performRebuild() {
    _hookIndex = 0;
    super.performRebuild();
  }
}
```

For more explanation of how they are implemented, here's a great article about how they did it in React: https://medium.com/@ryardley/react-hooks-not-magic-just-arrays-cd4f1857236e

## Limitations

Due to hooks being obtained based on their indexes, there are things you should _not_ do with hooks:

**Calls to `HookContext.use` should be made at top level and always in the same order**

In short,
DO:

```dart
Widget build(HookContext context) {
  final state = context.useState();
  // ....
}
```

DON'T:

```dart
Widget build(HookContext context) {
  if (condition) {
    final state = context.useState();
  }
  // ....
}
```

This may seem restricting at first, but the gain is more than worth it.

## How to use

Let's assume we want to make a counter app that saves its state into the local storage; something that would be pretty tedious using simple `StatefulWidget`.

Using hooks, we could think of making a `useLocalStorageInt` hook, that will automatically synchronize an integer with the local storage.

The hook would be used as followed:

```dart
class CounterApp extends HookWidget {
  @override
  Widget build(HookContext context) {
    AsyncSnapshot<int> count = useLocalStorageInt('counter', defaultValue: 0);

    if (count.)
  }
}
```
