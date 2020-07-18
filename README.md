[English](https://github.com/rrousselGit/flutter_hooks/blob/master/README.md) | [Português](https://github.com/rrousselGit/flutter_hooks/blob/master/resources/translations/pt_br/README.md)

[![Build Status](https://travis-ci.org/rrousselGit/flutter_hooks.svg?branch=master)](https://travis-ci.org/rrousselGit/flutter_hooks) [![codecov](https://codecov.io/gh/rrousselGit/flutter_hooks/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/flutter_hooks) [![pub package](https://img.shields.io/pub/v/flutter_hooks.svg)](https://pub.dartlang.org/packages/flutter_hooks) [![pub package](https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square)](https://github.com/Solido/awesome-flutter)

<img src="https://raw.githubusercontent.com/rrousselGit/flutter_hooks/master/flutter-hook.svg?sanitize=true" width="200">

# Flutter Hooks

A Flutter implementation of React hooks: https://medium.com/@dan_abramov/making-sense-of-react-hooks-fdbde8803889

Hooks are a new kind of object that manages a `Widget` life-cycles. They exist
for one reason: increase the code-sharing _between_ widgets by removing duplicates.

## Motivation

`StatefulWidget` suffers from a big problem: it is very difficult to reuse the
logic of say `initState` or `dispose`. An obvious example is `AnimationController`:

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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

All widgets that desire to use an `AnimationController` will have to reimplement
almost all of this from scratch, which is of course undesired.

Dart mixins can partially solve this issue, but they suffer from other problems:

- A given mixin can only be used once per class.
- Mixins and the class shares the same object.\
  This means that if two mixins define a variable under the same name, the result
  may vary between compilation fails to unknown behavior.

---

This library proposes a third solution:

```dart
class Example extends HookWidget {
  const Example({Key key, @required this.duration})
      : assert(duration != null),
        super(key: key);

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: duration);
    return Container();
  }
}
```

This code is strictly equivalent to the previous example. It still disposes the
`AnimationController` and still updates its `duration` when `Example.duration` changes.
But you're probably thinking:

> Where did all the logic go?

That logic moved into `useAnimationController`, a function included directly in
this library (see [Existing hooks](https://github.com/rrousselGit/flutter_hooks#existing-hooks)).
It is what we call a _Hook_.

Hooks are a new kind of objects with some specificities:

- They can only be used in the `build` method of a widget that mix-in `Hooks`.
- The same hook is reusable an infinite number of times
  The following code defines two independent `AnimationController`, and they are
  correctly preserved when the widget rebuild.

  ```dart
  Widget build(BuildContext context) {
    final controller = useAnimationController();
    final controller2 = useAnimationController();
    return Container();
  }
  ```

- Hooks are entirely independent of each other and from the widget.\
  This means they can easily be extracted into a package and published on
  [pub](https://pub.dartlang.org/) for others to use.

## Principle

Similarly to `State`, hooks are stored on the `Element` of a `Widget`. But instead
of having one `State`, the `Element` stores a `List<Hook>`. Then to use a `Hook`,
one must call `Hook.use`.

The hook returned by `use` is based on the number of times it has been called.
The first call returns the first hook; the second call returns the second hook,
the third returns the third hook, ...

If this is still unclear, a naive implementation of hooks is the following:

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

For more explanation of how they are implemented, here's a great article about
how they did it in React: https://medium.com/@ryardley/react-hooks-not-magic-just-arrays-cd4f1857236e

## Rules

Due to hooks being obtained from their index, some rules must be respected:

### DO always prefer your hooks with `use`:

```dart
Widget build(BuildContext context) {
  // starts with `use`, good name
  useMyHook();
  // doesn't start with `use`, could confuse people into thinking that this isn't a hook
  myHook();
  // ....
}
```

### DO call hooks unconditionally

```dart
Widget build(BuildContext context) {
  useMyHook();
  // ....
}
```

### DON'T wrap `use` into a condition

```dart
Widget build(BuildContext context) {
  if (condition) {
    useMyHook();
  }
  // ....
}
```

---

### About hot-reload

Since hooks are obtained from their index, one may think that hot-reload while refactoring will break the application.

But worry not, `HookWidget` overrides the default hot-reload behavior to work with hooks. Still, there are some situations in which the state of a Hook may get reset.

Consider the following list of hooks:

```dart
useA();
useB(0);
useC();
```

Then consider that after a hot-reload, we edited the parameter of `HookB`:

```dart
useA();
useB(42);
useC();
```

Here everything works fine; all hooks keep their states.

Now consider that we removed `HookB`. We now have:

```dart
useA();
useC();
```

In this situation, `HookA` keeps its state but `HookC` gets a hard reset.
This happens because when a refactoring is done, all hooks _after_ the first line impacted are disposed of.
Since `HookC` was placed after `HookB`, it got disposed of.

## How to use

There are two ways to create a hook:

- A function

  Functions are by far the most common way to write a hook. Thanks to hooks being
  composable by nature, a function will be able to combine other hooks to create
  a custom hook. By convention, these functions will be prefixed by `use`.

  The following defines a custom hook that creates a variable and logs its value
  on the console whenever the value changes:

  ```dart
  ValueNotifier<T> useLoggedState<T>(BuildContext context, [T initialData]) {
    final result = useState<T>(initialData);
    useValueChanged(result.value, (_, __) {
      print(result.value);
    });
    return result;
  }
  ```

- A class

  When a hook becomes too complex, it is possible to convert it into a class that extends `Hook`, which can then be used using `Hook.use`.\
  As a class, the hook will look very similar to a `State` and have access to
  life-cycles and methods such as `initHook`, `dispose` and `setState`
  It is usually a good practice to hide the class under a function as such:

  ```dart
  Result useMyHook(BuildContext context) {
    return use(const _TimeAlive());
  }
  ```

  The following defines a hook that prints the time a `State` has been alive.

  ```dart
  class _TimeAlive extends Hook<void> {
    const _TimeAlive();

    @override
    _TimeAliveState createState() => _TimeAliveState();
  }

  class _TimeAliveState extends HookState<void, _TimeAlive> {
    DateTime start;

    @override
    void initHook() {
      super.initHook();
      start = DateTime.now();
    }

    @override
    void build(BuildContext context) {}

    @override
    void dispose() {
      print(DateTime.now().difference(start));
      super.dispose();
    }
  }
  ```

## Existing hooks

Flutter_hooks comes with a list of reusable hooks already provided.

They are divided into different kinds:

### Primitives

A set of low-level hooks that interacts with the different life-cycles of a widget

| name                                                                                                              | description                                                      |
| ----------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| [useEffect](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useEffect.html)             | Useful for side-effects and optionally canceling them.           |
| [useState](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useState.html)               | Create variable and subscribes to it.                            |
| [useMemoized](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useMemoized.html)         | Cache the instance of a complex object.                          |
| [useContext](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useContext.html)           | Obtain the `BuildContext` of the building `HookWidget`.          |
| [useValueChanged](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useValueChanged.html) | Watches a value and calls a callback whenever the value changed. |

### Object binding

This category of hooks allows manipulating existing Flutter/Dart objects with hooks.
They will take care of creating/updating/disposing an object.

#### dart:async related:

| name                                                                                                                      | description                                                                  |
| ------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| [useStream](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useStream.html)                     | Subscribes to a `Stream` and return its current state in an `AsyncSnapshot`. |
| [useStreamController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useStreamController.html) | Creates a `StreamController` automatically disposed.                         |
| [useFuture](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useFuture.html)                     | Subscribes to a `Future` and return its current state in an `AsyncSnapshot`. |

#### Animation related:

| name                                                                                                                              | description                                              |
| --------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| [useSingleTickerProvider](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useSingleTickerProvider.html) | Creates a single usage `TickerProvider`.                 |
| [useAnimationController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useAnimationController.html)   | Creates an `AnimationController` automatically disposed. |
| [useAnimation](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useAnimation.html)                       | Subscribes to an `Animation` and return its value.       |

#### Listenable related:

| name                                                                                                                    | description                                                                                        |
| ----------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| [useListenable](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useListenable.html)           | Subscribes to a `Listenable` and mark the widget as needing build whenever the listener is called. |
| [useValueNotifier](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useValueNotifier.html)     | Creates a `ValueNotifier` automatically disposed.                                                  |
| [useValueListenable](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useValueListenable.html) | Subscribes to a `ValueListenable` and return its value.                                            |

#### Misc

A series of hooks with no particular theme.

| name                                                                                                                                | description                                            |
| ----------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| [useReducer](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useReducer.html)                             | An alternative to `useState` for more complex states.  |
| [usePrevious](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/usePrevious.html)                           | Returns the previous argument called to [usePrevious]. |
| [useTextEditingController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useTextEditingController-constant.html) | Create a `TextEditingController`                       |
| [useFocusNode](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useFocusNode.html)                         | Create a `FocusNode`                                   |
| [useTabController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useTabController.html)                 | Creates and disposes a `TabController`.                |
| [useScrollController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useScrollController.html)           | Creates and disposes a `ScrollController`.             |

## Contributions

Contributions are welcomed!

If you feel that a hook is missing, feel free to open a pull-request.

For a custom-hook to be merged, you will need to do the following:

- Describe the use-case.

  Open an issue explaining why we need this hook, how to use it, ...
  This is important as a hook will not get merged if the hook doens't appeal to
  a large number of people.

  If your hook is rejected, don't worry! A rejection doesn't mean that it won't
  be merged later in the future if more people shows an interest in it.
  In the mean-time, feel free to publish your hook as a package on https://pub.dev.

- Write tests for your hook

  A hook will not be merged unles fully tested, to avoid breaking it inadvertendly
  in the future.

- Add it to the Readme & write documentation for it.
