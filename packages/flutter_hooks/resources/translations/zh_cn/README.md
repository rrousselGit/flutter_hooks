[English](https://github.com/rrousselGit/flutter_hooks/blob/master/README.md) | [Português](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/pt_br/README.md) | [한국어](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/ko_kr/README.md) | [简体中文](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/zh_cn/README.md)

[![Build](https://github.com/rrousselGit/flutter_hooks/workflows/Build/badge.svg)](https://github.com/rrousselGit/flutter_hooks/actions?query=workflow%3ABuild) [![codecov](https://codecov.io/gh/rrousselGit/flutter_hooks/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/flutter_hooks) [![pub package](https://img.shields.io/pub/v/flutter_hooks.svg)](https://pub.dev/packages/flutter_hooks) [![pub package](https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square)](https://github.com/Solido/awesome-flutter)
<a href="https://discord.gg/Bbumvej"><img src="https://img.shields.io/discord/765557403865186374.svg?logo=discord&color=blue" alt="Discord"></a>

<img src="https://raw.githubusercontent.com/rrousselGit/flutter_hooks/master/packages/flutter_hooks/flutter-hook.svg?sanitize=true" width="200">

# Flutter Hooks

一个 React 钩子在 Flutter 上的实现：<https://medium.com/@dan_abramov/making-sense-of-react-hooks-fdbde8803889>

钩子是一种用来管理 `Widget` 生命周期的新对象，为减少重复代码、增加组件间复用性而存在。

## 动机

`StatefulWidget` 有个大问题，它很难减少 `initState` 或 `dispose` 的调用，一个简明的例子就是 `AnimationController`：

```dart
class Example extends StatefulWidget {
  final Duration duration;

  const Example({Key? key, required this.duration})
      : super(key: key);

  @override
  _ExampleState createState() => _ExampleState();
}

class _ExampleState extends State<Example> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didUpdateWidget(Example oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller!.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

所有想要使用 `AnimationController` 的组件都几乎必须从头开始重新实现这些逻辑，这当然不是我们想要的。

Dart 的 mixins 特性能部分解决这个问题，但随之又有其它问题：

- 一个给定的 mixin 只能被一个类使用一次
- Mixin 和类共用一个对象\
  这意味着如果两个 mixin 用一个变量名分别定义自己的变量，结果要么是编译失败，要么行为诡异。

---

这个库提供了另一个解决方法：

```dart
class Example extends HookWidget {
  const Example({Key? key, required this.duration})
      : super(key: key);

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: duration);
    return Container();
  }
}
```

这段代码和之前的例子有一样的功能。\
它仍然会 dispose `AnimationController`，并在 `Example.duration` 改变时更新它的 `duration`。\
但猜你在想：

> 那些逻辑都哪去了？

那些逻辑都已经被移入了 `useAnimationController` 里，这是这个库直接带有的（看看 [已有的钩子](https://github.com/Cierra-Runis/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/zh_cn/README.md#%E5%B7%B2%E6%9C%89%E7%9A%84%E9%92%A9%E5%AD%90) ）——这就是我们所说的 _钩子_。

钩子是一种有着如下部分特性的新对象：

- 只能在混入了 `Hooks` 的组件的 `build` 方法内使用
- 同类的钩子能复用任意多次\
  如下的代码定义了两个独立的 `AnimationController`，并且都在组件重建时被正确的保留

  ```dart
  Widget build(BuildContext context) {
    final controller = useAnimationController();
    final controller2 = useAnimationController();
    return Container();
  }
  ```

- 钩子和其它钩子与组件完全独立\
  这说明他们能被很简单的抽离到一个包并发布到 [pub](https://pub.dev/) 上去给其他人用

## 原理

与 `State` 类似，钩子被存在 `Widget` 的 `Element` 里。但和存个 `State` 不一样，`Element` 存的是 `List<Hook>`。\
再就是想要使用 `Hook` 的话，就必须调用 `Hook.use`。

由 `use` 返回的钩子由其被调用的次数决定。\
第一次调用返回第一个钩子，第二次返回第二个，第三次返回第三个这样。

如果还是不太能理解的话，钩子的一个原生实现可能长下面这样：

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

想要知道有关钩子是怎么实现的更多解释的话，这里有篇挺不错的 [文章](https://medium.com/@ryardley/react-hooks-not-magic-just-arrays-cd4f1857236e) 讲钩子在 React 是怎么实现的。

## 规定

由于钩子由它们的 index 保留，有些规定是必须要遵守的：

### _要_ 一直使用 `use` 作为你钩子的前缀

```dart
Widget build(BuildContext context) {
  // 以 `use` 开头，非常好名字
  useMyHook();
  // 不以 `use` 开头，会让人以为这不是一个钩子
  myHook();
  // ....
}
```

### _要_ 直接调用钩子

```dart
Widget build(BuildContext context) {
  useMyHook();
  // ....
}
```

### _不要_ 将 `use` 包到条件语句里

```dart
Widget build(BuildContext context) {
  if (condition) {
    useMyHook();
  }
  // ....
}
```

---

### 有关热重载

由于钩子由它们的 index 保留，可能有人认为在重构时热重载会搞崩程序。

但是冇问题，为了能使用钩子，`HookWidget` 覆写了默认的热重载行为，但还有一些情况下钩子的状态会被重置。

设想如下三个钩子：

```dart
useA();
useB(0);
useC();
```

然后我们在热重载后修改 `HookB` 的参数：

```dart
useA();
useB(42);
useC();
```

那么一切正常，所有的钩子都保留了他们的状态。

现在再删掉 `HookB` 试试：

```dart
useA();
useC();
```

在这种情况下，`HookA` 会保留它的状态，但 `HookC` 会被强制重置。\
这是因为重构并热重载后，在第一个被影响的钩子 _之后_ 的所有钩子都会被 dispose 掉。\
因此，由于 `HookC` 在 `HookB` _之后_，所以它会被 dispose 掉。

## 如何创建钩子

这有两种方法：

- 函数式钩子

  函数是目前用来写钩子的最常用方法。\
  多亏钩子能被自然的组合，一个函数就能将其他的钩子组合为一个复杂的自定义钩子。\
  而且我们规定好了这些函数都以 `use` 为前缀。

  如下代码构建了一个自定义钩子，其创建了一个变量，并在变量改变时在终端显示日志。

  ```dart
  ValueNotifier<T> useLoggedState<T>([T initialData]) {
    final result = useState<T>(initialData);
    useValueChanged(result.value, (_, __) {
      print(result.value);
    });
    return result;
  }
  ```

- 类钩子

  当一个钩子变得过于复杂时，可以将其转化为一个继承 `Hook` 的类——然后就能拿来调用 `Hook.use`。\
  作为一个类，钩子看起来和 `State` 类差不多，有着组件的生命周期和方法，比如 `initHook`、`dispose`和`setState`。

  而且一个好的实践是将类藏在一个函数后面：

  ```dart
  Result useMyHook() {
    return use(const _TimeAlive());
  }
  ```

  如下代码构建了一个自定义钩子，其能在其被 dispose 时打印其状态存在的总时长。

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

## 已有的钩子

Flutter_Hooks 已经包含一些不同类别的可复用的钩子：

### 基础类别

A set of low-level hooks that interact with the different life-cycles of a widget

| Name                                                                                                     | Description                                                         |
| -------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| [useEffect](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useEffect.html)             | Useful for side-effects and optionally canceling them.              |
| [useState](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useState.html)               | Creates a variable and subscribes to it.                            |
| [useMemoized](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useMemoized.html)         | Caches the instance of a complex object.                            |
| [useRef](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useRef.html)                   | Creates an object that contains a single mutable property.          |
| [useCallback](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useCallback.html)         | Caches a function instance.                                         |
| [useContext](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useContext.html)           | Obtains the `BuildContext` of the building `HookWidget`.            |
| [useValueChanged](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useValueChanged.html) | Watches a value and triggers a callback whenever its value changed. |

### Object-binding

This category of hooks the manipulation of existing Flutter/Dart objects with hooks.
They will take care of creating/updating/disposing an object.

#### dart:async related hooks:

| Name                                                                                                             | Description                                                                   |
| ---------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| [useStream](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useStream.html)                     | Subscribes to a `Stream` and returns its current state as an `AsyncSnapshot`. |
| [useStreamController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useStreamController.html) | Creates a `StreamController` which will automatically be disposed.            |
| [useOnStreamChange](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useOnStreamChange.html) | Subscribes to a `Stream`, registers handlers, and returns the `StreamSubscription`.
| [useFuture](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useFuture.html)                     | Subscribes to a `Future` and returns its current state as an `AsyncSnapshot`. |

#### Animation related hooks:

| Name                                                                                                                     | Description                                                            |
| ------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------- |
| [useSingleTickerProvider](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useSingleTickerProvider.html) | Creates a single usage `TickerProvider`.                               |
| [useAnimationController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useAnimationController.html)   | Creates an `AnimationController` which will be automatically disposed. |
| [useAnimation](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useAnimation.html)                       | Subscribes to an `Animation` and returns its value.                    |

#### Listenable related hooks:

| Name                                                                                                                 | Description                                                                                         |
| -------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| [useListenable](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useListenable.html)                 | Subscribes to a `Listenable` and marks the widget as needing build whenever the listener is called. |
| [useListenableSelector](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useListenableSelector.html) | Similar to `useListenable`, but allows filtering UI rebuilds                                        |
| [useValueNotifier](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useValueNotifier.html)           | Creates a `ValueNotifier` which will be automatically disposed.                                     |
| [useValueListenable](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useValueListenable.html)       | Subscribes to a `ValueListenable` and return its value.                                             |

#### Misc hooks:

A series of hooks with no particular theme.

| Name                                                                                                                                 | Description                                                                |
| ------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------- |
| [useReducer](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useReducer.html)                                       | An alternative to `useState` for more complex states.                      |
| [usePrevious](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/usePrevious.html)                                     | Returns the previous argument called to [usePrevious].                     |
| [useTextEditingController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useTextEditingController-constant.html)  | Creates a `TextEditingController`.                                         |
| [useFocusNode](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useFocusNode.html)                                   | Creates a `FocusNode`.                                                     |
| [useTabController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useTabController.html)                           | Creates and disposes a `TabController`.                                    |
| [useScrollController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useScrollController.html)                     | Creates and disposes a `ScrollController`.                                 |
| [usePageController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/usePageController.html)                         | Creates and disposes a `PageController`.                                   |
| [useAppLifecycleState](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useAppLifecycleState.html)                   | Returns the current `AppLifecycleState` and rebuilds the widget on change. |
| [useOnAppLifecycleStateChange](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useOnAppLifecycleStateChange.html)   | Listens to `AppLifecycleState` changes and triggers a callback on change.  |
| [useTransformationController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useTransformationController.html)     | Creates and disposes a `TransformationController`.                         |
| [useIsMounted](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useIsMounted.html)                                   | An equivalent to `State.mounted` for hooks.                                |
| [useAutomaticKeepAlive](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useAutomaticKeepAlive.html)                 | An equivalent to the `AutomaticKeepAlive` widget for hooks.                |
| [useOnPlatformBrightnessChange](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useOnPlatformBrightnessChange.html) | Listens to platform `Brightness` changes and triggers a callback on change.|
| [useSearchController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useSearchController.html)                     | Creates and disposes a `SearchController`.                                 |
| [useMaterialStatesController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useMaterialStatesController.html)     | Creates and disposes a `MaterialStatesController`.                         |
| [useExpansionTileController](https://api.flutter.dev/flutter/material/ExpansionTileController-class.html)                            | Creates a `ExpansionTileController`.                                       |

## Contributions

Contributions are welcomed!

If you feel that a hook is missing, feel free to open a pull-request.

For a custom-hook to be merged, you will need to do the following:

- Describe the use-case.

  Open an issue explaining why we need this hook, how to use it, ...
  This is important as a hook will not get merged if the hook doesn't appeal to
  a large number of people.

  If your hook is rejected, don't worry! A rejection doesn't mean that it won't
  be merged later in the future if more people show interest in it.
  In the mean-time, feel free to publish your hook as a package on https://pub.dev.

- Write tests for your hook

  A hook will not be merged unless fully tested to avoid inadvertently breaking it
  in the future.

- Add it to the README and write documentation for it.

## Sponsors

<p align="center">
  <a href="https://raw.githubusercontent.com/rrousselGit/freezed/master/sponsorkit/sponsors.svg">
    <img src='https://raw.githubusercontent.com/rrousselGit/freezed/master/sponsorkit/sponsors.svg'/>
  </a>
</p>
