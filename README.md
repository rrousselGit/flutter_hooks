[![Build Status](https://travis-ci.org/rrousselGit/flutter_hooks.svg?branch=master)](https://travis-ci.org/rrousselGit/flutter_hooks) [![codecov](https://codecov.io/gh/rrousselGit/flutter_hooks/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/flutter_hooks) [![pub package](https://img.shields.io/pub/v/flutter_hooks.svg)](https://pub.dartlang.org/packages/flutter_hooks) [![pub package](https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square)](https://github.com/Solido/awesome-flutter)

<img src="https://raw.githubusercontent.com/rrousselGit/flutter_hooks/master/flutter-hook.svg?sanitize=true" width="200">

# Flutter Hooks

A flutter implementation of React hooks: https://medium.com/@dan_abramov/making-sense-of-react-hooks-fdbde8803889

Hooks are a new kind of object that manages a `Widget` life-cycles. They exist for one reason: increase the code sharing _between_ widgets and as a complete replacement for `StatefulWidget`.

## Motivation

`StatefulWidget` suffer from a big problem: it is very difficult to reuse the logic of say `initState` or `dispose`. An obvious example is `AnimationController`:

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

All widgets that desire to use an `AnimationController` will have to reimplement almost of all this from scratch, which is of course undesired.

Dart mixins can partially solve this issue, but they suffer from other problems:

- A given mixin can only be used once per class.
- Mixins and the class shares the same object. This means that if two mixins define a variable under the same name, the end result may vary between compilation fail to unknown behavior.

---

This library propose a third solution:

```dart
class Example extends HookWidget {
  final Duration duration;

  const Example({Key key, @required this.duration})
      : assert(duration != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: duration);
    return Container();
  }
}
```

This code is strictly equivalent to the previous example. It still disposes the `AnimationController` and still updates its `duration` when `Example.duration` changes.
But you're probably thinking:

> Where did all the logic go?

That logic moved into `useAnimationController`, a function included directly in this library (see https://github.com/rrousselGit/flutter_hooks#existing-hooks). It is what we call a _Hook_.

Hooks are a new kind of objects with some specificities:

- They can only be used in the `build` method of a `HookWidget`.
- The same hook is reusable an infinite number of times
  The following code defines two independent `AnimationController`, and they are correctly preserved when the widget rebuild.

```dart
Widget build(BuildContext context) {
  final controller = useAnimationController();
  final controller2 = useAnimationController();
  return Container();
}
```

- Hooks are entirely independent of each other and from the widget. Which means they can easily be extracted into a package and published on [pub](https://pub.dartlang.org/) for others to use.

## Principle

Similarly to `State`, hooks are stored on the `Element` of a `Widget`. But instead of having one `State`, the `Element` stores a `List<Hook>`. Then to use a `Hook`, one must call `Hook.use`.

The hook returned by `use` is based on the number of times it has been called. The first call returns the first hook; the second call returns the second hook, the third returns the third hook, ...

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

For more explanation of how they are implemented, here's a great article about how they did it in React: https://medium.com/@ryardley/react-hooks-not-magic-just-arrays-cd4f1857236e

## Rules

Due to hooks being obtained from their index, there are some rules that must be respected:

### DO call `use` unconditionally

```dart
Widget build(BuildContext context) {
  Hook.use(MyHook());
  // ....
}
```

### DON'T wrap `use` into a condition

```dart
Widget build(BuildContext context) {
  if (condition) {
    Hook.use(MyHook());
  }
  // ....
}
```

---

### DO always call all the hooks:

```dart
Widget build(BuildContext context) {
  Hook.use(Hook1());
  Hook.use(Hook2());
  // ....
}
```

### DON'T aborts `build` method before all hooks have been called:

```dart
Widget build(BuildContext context) {
  Hook.use(Hook1());
  if (condition) {
    return Container();
  }
  Hook.use(Hook2());
  // ....
}
```

---

### About hot-reload

Since hooks are obtained from their index, one may think that hot-reload while refactoring will break the application.

But worry not, `HookWidget` overrides the default hot-reload behavior to work with hooks. Still, there are some situations in which the state of a Hook may get reset.

Consider the following list of hooks:

```dart
Hook.use(HookA());
Hook.use(HookB(0));
Hook.use(HookC(0));
```

Then consider that after a hot-reload, we edited the parameter of `HookB`:

```dart
Hook.use(HookA());
Hook.use(HookB(42));
Hook.use(HookC());
```

Here everything works fine; all hooks keep their states.

Now consider that we removed `HookB`. We now have:

```dart
Hook.use(HookA());
Hook.use(HookC());
```

In this situation, `HookA` keeps its state but `HookC` gets a hard reset.
This happens because when a refactoring is done, all hooks _after_ the first line impacted are disposed. Since `HookC` was placed after `HookB`, is got disposed.

## How to use

There are two ways to create a hook:

- A function

Functions is by far the most common way to write a hook. Thanks to hooks being composable by nature, a function will be able to combine other hooks to create a custom hook. By convention these functions will be prefixed by `use`.

The following defines a custom hook that creates a variable and logs its value on the console whenever the value changes:

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

When a hook becomes too complex, it is possible to convert it into a class that extends `Hook`, which can then be used using `Hook.use`. As a class, the hook will look very similar to a `State` and have access to life-cycles and methods such as `initHook`, `dispose` and `setState`. It is usually a good practice to hide the class under a function as such:

```dart
Result useMyHook(BuildContext context) {
  return Hook.use(_MyHook());
}
```

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
  void build(BuildContext context) {
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

Flutter_hooks comes with a list of reusable hooks already provided. They are static methods free to use that includes:

- useEffect

Useful to trigger side effects in a widget and dispose objects. It takes a callback and calls it immediately. That callback may optionally return a function, which will be called when the widget is disposed.

By default, the callback is called on every `build`, but it is possible to override that behavior by passing a list of objects as the second parameter. The callback will then be called only when something inside the list has changed.

The following call to `useEffect` subscribes to a `Stream` and cancel the subscription when the widget is disposed:

```dart
Stream stream;
useEffect(() {
    final subscription = stream.listen(print);
    // This will cancel the subscription when the widget is disposed
    // or if the callback is called again.
    return subscription.cancel;
  },
  // when the stream change, useEffect will call the callback again.
  [stream],
);
```

- useState

Defines + watch a variable and whenever the value change, calls `setState`.

The following code uses `useState` to make a counter application:

```dart
class Counter extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final counter = useState(0);

    return GestureDetector(
      // automatically triggers a rebuild of Counter widget
      onTap: () => counter.value++,
      child: Text(counter.value.toString()),
    );
  }
}
```

- useReducer

An alternative to useState for more complex states.

`useReducer` manages an read only state that can be updated by dispatching actions which are interpreted by a `Reducer`.

The following makes a counter app with both a "+1" and "-1" button:

```dart
class Counter extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final counter = useReducer(_counterReducer, initialState: 0);

    return Column(
      children: <Widget>[
        Text(counter.state.toString()),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => counter.dispatch('increment'),
        ),
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () => counter.dispatch('decrement'),
        ),
      ],
    );
  }

  int _counterReducer(int state, String action) {
    switch (action) {
      case 'increment':
        return state + 1;
      case 'decrement':
        return state - 1;
      default:
        return state;
    }
  }
}
```

- useContext

Returns the `BuildContext` of the currently building `HookWidget`. This is useful when writing custom hooks that want to manipulate the `BuildContext`. 

```dart
MyInheritedWidget useMyInheritedWidget() {
  BuildContext context = useContext();
  return MyInheritedWidget.of(context);
}
```

- useMemoized

Takes a callback, calls it synchronously and returns its result. The result is then stored to that subsequent calls will return the same result without calling the callback.

By default, the callback is called only on the first build. But it is optionally possible to specify a list of objects as the second parameter. The callback will then be called again whenever something inside the list has changed.

The following sample make an http call and return the created `Future`. And if `userId` changes, a new call will be made:

```dart
String userId;
final Future<http.Response> response = useMemoized(() {
  return http.get('someUrl/$userId');
}, [userId]);
```

- useValueChanged

Takes a value and a callback, and call the callback whenever the value changed. The callback can optionally return an object, which will be stored and returned as the result of `useValueChanged`.

The following example implicitly starts a tween animation whenever `color` changes:

```dart
AnimationController controller;
Color color;

final colorTween = useValueChanged(
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

- useAnimationController, useStreamController, useSingleTickerProvider, useValueNotifier

A set of hooks that handles the whole life-cycle of an object. These hooks will take care of both creating, disposing and updating the object.

They are the equivalent of both `initState`, `dispose` and `didUpdateWidget` for that specific object.

```dart
Duration duration;
AnimationController controller = useAnimationController(
  // duration is automatically updates when the widget is rebuilt with a different `duration`
  duration: duration,
);
```

- useStream, useFuture, useAnimation, useValueListenable, useListenable

A set of hooks that subscribes to an object and calls `setState` accordingly.

```dart
Stream<int> stream;
// automatically rebuild the widget when a new value is pushed to the stream
AsyncSnapshot<int> snapshot = useStream(stream);
```
