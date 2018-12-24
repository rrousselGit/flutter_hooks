[![Build Status](https://travis-ci.org/rrousselGit/flutter_hooks.svg?branch=master)](https://travis-ci.org/rrousselGit/flutter_hooks) [![codecov](https://codecov.io/gh/rrousselGit/flutter_hooks/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/flutter_hooks)

[![pub package](https://img.shields.io/pub/v/flutter_hooks.svg)](https://pub.dartlang.org/packages/flutter_hooks)

<img src="https://raw.githubusercontent.com/rrousselGit/flutter_hooks/master/flutter-hook.svg?sanitize=true" width="200">

# Flutter Hooks

A flutter implementation of React hooks: https://medium.com/@dan_abramov/making-sense-of-react-hooks-fdbde8803889

Hooks are a new kind of object that manages a `Widget` life-cycles. They exists for one reason: increase the code sharing _between_ widgets and as a complete replacement for `StatefulWidget`.

## Motivation

`StatefulWidget` suffer from a big problem: it is very difficult reuse the logic of say `initState` or `dispose`. An obvious example is `AnimationController`:

```dart
class Example extends StatefulWidget {
  final Duration duration;

  const Example({Key key, @required this.duration})
      : assert(duration != null),
        super(key: key);

  @override
  _ExampleState createState() => _ExampleState();
}

class _ExampleState extends State<Example> with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didUpdateWidget(Example oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
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

All widgets that desires to use an `AnimationController` will have to reimplement the creation/destruction these life-cycles from scratch, which is of course undesired.

Dart mixins can partially solve this issue, but they suffer from other issues:

-   One given mixin can only be used once per class.
-   Mixins and the class shares the same type. This means that if two mixins defines a variable under the same name, the end result may vary between compilation fail to unknown behavior.

---

Now let's reimplement the previous example using this library:

```dart
class Example extends HookWidget {
  final Duration duration;

  const Example({Key key, @required this.duration})
      : assert(duration != null),
        super(key: key);

  @override
  Widget build(HookContext context) {
    final controller = context.useAnimationController(duration: duration);
    return Container();
  }
}
```

This code is strictly equivalent to the previous example. It still disposes the `AnimationController` and still updates its `duration` when `Example.duration` changes.
But you're probably thinking:

> Where did all the previous logic go?

That logic moved into `useAnimationController`. This function is what we call a _Hook_. Hooks have a few specificies:

-   They can be used only in the `build` method of a `HookWidget`.
-   The same hook can be reused multiple times without variable conflict.
-   Hooks are entirely independent from each others and from the widget. Which means they can easily be extracted into a package and published on [pub](https://pub.dartlang.org/) for others to use.

## Principle

Hooks, similarily to `State`, are stored on the `Element` associated to a `Widget`. But instead of having one `State`, the `Element` stores a `List<Hook>`. Then obtain the content of a `Hook`, one must call `HookContext.use`.

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

Due to hooks being obtained based on their indexes, there are some rules for using hooks that must be respected:

### DO call `use` unconditionally

```dart
Widget build(HookContext context) {
  context.use(MyHook());
  // ....
}
```

### DON'T call wrap `use` into a condition

```dart
Widget build(HookContext context) {
  if (condition) {
    context.use(MyHook());
  }
  // ....
}
```

---

### DO always call all the hooks:

```dart
Widget build(HookContext context) {
  context.use(Hook1());
  context.use(Hook2());
  // ....
}
```

### DON'T abort `build` method before all hooks have been called:

```dart
Widget build(HookContext context) {
  context.use(Hook1());
  if (condition) {
    return Container();
  }
  context.use(Hook2());
  // ....
}
```

____

### About hot-reload

Since hooks are obtained based on their index, one may think that hot-reload will break the application. But that is not the case.

`HookWidget` overrides the default hot-reload behavior to work with hooks. But in certain situations, the state of a Hook may get reset.
Consider the following list of hooks:

- A()
- B(0)
- C()

Then consider that after a hot-reload, we edited the parameter of B:

- A()
- B(42)
- C()

Here there are no issue. All hooks keeps their states. 

Now consider that we removed B. We now have:

- A()
- C()

In this situation, A keeps its state but C gets a hard reset.

## How to use

There are two way to create a hook:

-   A function

Due to hooks composable nature, functions are the most common solution for custom hooks.
They will have their name prefixed by `use` and take a `HookContext` as argument.

The following defines a custom hook that creates a variable and log its value on the console whenever the value change:

```dart
ValueNotifier<T> useLoggedState<T>(HookContext context, [T initialData]) {
  final result = context.useState<T>(initialData);
  context.useValueChanged(result.value, (_, __) {
    print(result.value);
  });
  return result;
}
```

-   A class

When a hook becomes too complex, it is possible to convert it into a class that extends `Hook`, which can then be used using `HookContext.use`. As a class, the hook will look very similar to a `State` and have access to life-cycles and methods such as `initHook`, `dispose` and `setState`.

It is prefered to use functions over classes whenever possible, and to hide classes under a function.

The following defines a hook that prints the time a `State` has been alive.

```dart
class _TimeAlive<T> extends Hook<void> {
  const _TimeAlive();

  @override
  _TimeAliveState<T> createState() => _TimeAliveState<T>();
}

class _TimeAliveState<T> extends HookState<void, _TimeAlive<T>> {
  DateTime start;

  @override
  void initHook() {
    super.initHook();
    start = DateTime.now();
  }

  @override
  void build(HookContext context) {
    // this hook doesn't create anything nor uses other hooks
  }

  @override
  void dispose() {
    print(DateTime.now().difference(start));
    super.dispose();
  }
}

```

## Existing hooks

`HookContext` comes with a list of predefined hooks that are commonly used. They can be used directly on the `HookContext` instance. The existing hooks are:

-   useEffect

Useful to trigger side effects in a widget and dispose objects. It takes a callback and calls it immediatly. That callback may optionally return a function, which will be called when the widget is disposed.

By default the callback is called on every `build`, but it is possible to override that behavior by passing a list of objects as second parameter. The callback will then be called only when something inside the list has changed.

The following call to `useEffect` subscribes to a `Stream` and cancel the subscription when the widget is disposed:

```dart
Stream stream;
context.useEffect(() {
    final subscribtion = stream.listen(print);
    // This will cancel the subscribtion when the widget is disposed
    // or if the callback is called again.
    return subscribtion.cancel;
  },
  // when the stream change, useEffect will call the callback again.
  [stream],
);
```

-   useState

Defines + watch a variable and whenever the value change, calls `setState`.

The following uses `useState` to make a simple counter application:

```dart
class Counter extends HookWidget {
  @override
  Widget build(HookContext context) {
    final counter = context.useState(0);

    return GestureDetector(
      onTap: () => counter.value++,
      child: Text(counter.value.toString()),
    );
  }
}
```

-   useMemoized

Takes a callback that creates a value, call it, and stores its result so that next time, the value is reused.

By default the callback is called only on the first build. But it is optionally possible to specify a list of objects as second parameter. The callback will then be called again whenever something inside the list has changed.

The following sample make an http call and return the created `Future` whenever `userId` changes:

```dart
String userId;
final Future<http.Response> response = context.useMemoized(() {
  return http.get('someUrl/$userId');
}, [userId]);
```

-   useValueChanged

Takes a value and a callback, and call the callback whenever the value changed. The callback can optionally return an object, which will be stored and returned as the result of `useValueChanged`.

The following example implictly starts a tween animation whenever `color` changes:

```dart
AnimationController controller;
Color color;

final colorTween = context.useValueChanged(
    color,
    (Color oldColor, Animation<Color> oldAnimation) {
      return ColorTween(
        begin: oldAnimation?.value ?? oldColor,
        end: color,
      ).animate(controller..forward(from: 0));
    },
  ) ??
  AlwaysStoppedAnimation(color);
```
