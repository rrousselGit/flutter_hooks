[English](https://github.com/rrousselGit/flutter_hooks/blob/master/README.md) | [Português](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/pt_br/README.md) | [한국어](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/ko_kr/README.md) | [简体中文](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/zh_cn/README.md)

[![Build](https://github.com/rrousselGit/flutter_hooks/workflows/Build/badge.svg)](https://github.com/rrousselGit/flutter_hooks/actions?query=workflow%3ABuild) [![codecov](https://codecov.io/gh/rrousselGit/flutter_hooks/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/flutter_hooks) [![pub package](https://img.shields.io/pub/v/flutter_hooks.svg)](https://pub.dev/packages/flutter_hooks) [![pub package](https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square)](https://github.com/Solido/awesome-flutter)

<a href="https://discord.gg/6G6ZWkk3fQ"><img src="https://img.shields.io/discord/765557403865186374.svg?logo=discord&color=blue" alt="Discord"></a>

<p align="center">
  <img src="https://raw.githubusercontent.com/rrousselGit/flutter_hooks/master/packages/flutter_hooks/flutter-hook.svg?sanitize=true" width="200">
</p>

# Flutter Hooks

一个 React 钩子在 Flutter 上的实现：[Making Sense of React Hooks](https://medium.com/@dan_abramov/making-sense-of-react-hooks-fdbde8803889)

钩子是一种用来管理 `Widget` 生命周期的新对象，以减少重复代码、增加组件间复用性。

## 动机

`StatefulWidget` 有个大问题，它很难减少 `initState` 或 `dispose` 的调用，一个简明的例子就是 `AnimationController`：

```dart
class Example extends StatefulWidget {
  const Example({super.key, required this.duration});

  final Duration duration;

  @override
  _ExampleState createState() => _ExampleState();
}

class _ExampleState extends State<Example> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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

所有想要使用 `AnimationController` 的组件都几乎必须从头开始重新实现这些逻辑，这当然不是我们想要的。

Dart 的 mixin 能部分解决这个问题，但随之又有其它问题：

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
它仍然会 dispose `AnimationController`，并在 `Example.duration` 改变时更新它的 `duration`。

但猜你在想：

> 那些逻辑都哪去了？

那些逻辑都已经被移入了 `useAnimationController` 里，这是这个库直接带有的（见 [已有的钩子](https://github.com/Cierra-Runis/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/zh_cn/README.md#%E5%B7%B2%E6%9C%89%E7%9A%84%E9%92%A9%E5%AD%90) ）——这就是我们所说的 _钩子_。

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

如果还是不太能理解的话，钩子的一个雏形可能长下面这样：

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

想要更多有关钩子是怎么实现的解释的话，这里有篇讲钩子在 React 是怎么实现的挺不错的 [文章](https://medium.com/@ryardley/react-hooks-not-magic-just-arrays-cd4f1857236e)。

## 约定

由于钩子由它们的 index 保留，有些约定是必须要遵守的：

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

冇问题的，为了能使用钩子，`HookWidget` 覆写了默认的热重载行为，但还有一些情况下钩子的状态会被重置。

设想如下三个钩子：

```dart
useA();
useB(0);
useC();
```

接下来我们在热重载后修改 `HookB` 的参数：

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
  而且我们约定好了这些函数都以 `use` 为前缀。

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

与组件不同生命周期交互的低级钩子。

| 名称                                                                                                     | 介绍                                        |
| -------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| [useEffect](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useEffect.html)             | 对副作用很有用，可以选择取消它们            |
| [useState](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useState.html)               | 创建并订阅一个变量                          |
| [useMemoized](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useMemoized.html)         | 缓存复杂对象的实例                          |
| [useRef](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useRef.html)                   | 创建一个包含单个可变属性的对象              |
| [useCallback](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useCallback.html)         | 缓存一个函数的实例                          |
| [useContext](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useContext.html)           | 包含构建中的 `HookWidget` 的 `BuildContext` |
| [useValueChanged](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useValueChanged.html) | 监听一个值并在其改变时触发回调              |

### 绑定对象

这类钩子用以操作现有的 Flutter 及 Dart 对象。\
它们负责创建、更新以及 dispose 对象。

#### dart:async 相关

| 名称                                                                                                             | 介绍                                                       |
| ---------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| [useStream](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useStream.html)                     | 订阅一个 `Stream`，并以 `AsyncSnapshot` 返回它目前的状态   |
| [useStreamController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useStreamController.html) | 创建一个会自动 dispose 的 `StreamController`               |
| [useOnStreamChange](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useOnStreamChange.html)     | 订阅一个 `Stream`，注册处理函数，返回 `StreamSubscription` |
| [useFuture](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useFuture.html)                     | 订阅一个 `Future` 并以 `AsyncSnapshot` 返回它目前的状态    |

#### Animation 相关

| 名称                                                                                                                     | 介绍                                            |
| ------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------- |
| [useSingleTickerProvider](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useSingleTickerProvider.html) | 创建单一用途的 `TickerProvider`                 |
| [useAnimationController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useAnimationController.html)   | 创建一个会自动 dispose 的 `AnimationController` |
| [useAnimation](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useAnimation.html)                       | 订阅一个 `Animation` 并返回它的值               |

#### Listenable 相关

| 名称                                                                                                                 | 介绍                                                 |
| -------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| [useListenable](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useListenable.html)                 | 订阅一个 `Listenable` 并在 listener 调用时将组件标脏 |
| [useListenableSelector](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useListenableSelector.html) | 和 `useListenable` 类似，但支持过滤 UI 重建          |
| [useValueNotifier](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useValueNotifier.html)           | 创建一个会自动 dispose 的 `ValueNotifier`            |
| [useValueListenable](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useValueListenable.html)       | 订阅一个 `ValueListenable` 并返回它的值              |

#### 杂项

一组无明确主题的钩子。

| 名称                                                                                                                                 | 介绍                                               |
| ------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------- |
| [useReducer](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useReducer.html)                                       | 对于更复杂的状态，用以替代 `useState`              |
| [usePrevious](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/usePrevious.html)                                     | 返回调用 `usePrevious` 的上一个参数                |
| [useTextEditingController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useTextEditingController-constant.html)  | 创建一个 `TextEditingController`                   |
| [useFocusNode](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useFocusNode.html)                                   | 创建一个 `FocusNode`                               |
| [useTabController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useTabController.html)                           | 创建并自动 dispose 一个 `TabController`            |
| [useScrollController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useScrollController.html)                     | 创建并自动 dispose 一个 `ScrollController`         |
| [usePageController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/usePageController.html)                         | 创建并自动 dispose 一个 `PageController`           |
| [useAppLifecycleState](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useAppLifecycleState.html)                   | 返回当前的 `AppLifecycleState`，并在改变时重建组件 |
| [useOnAppLifecycleStateChange](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useOnAppLifecycleStateChange.html)   | 监听 `AppLifecycleState` 并在其改变时触发回调      |
| [useTransformationController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useTransformationController.html)     | 创建并自动 dispose 一个 `TransformationController` |
| [useIsMounted](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useIsMounted.html)                                   | 对钩子而言和 `State.mounted` 一样                  |
| [useAutomaticKeepAlive](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useAutomaticKeepAlive.html)                 | 对钩子而言和 `AutomaticKeepAlive` 一样             |
| [useOnPlatformBrightnessChange](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useOnPlatformBrightnessChange.html) | 监听平台 `Brightness` 并在其改变时触发回调         |
| [useWidgetStatesController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useWidgetStatesController.html)     | 创建并自动 dispose 一个 `WidgetStatesController` |
| [useExpansionTileController](https://api.flutter.dev/flutter/material/ExpansionTileController-class.html)                            | 创建一个 `ExpansionTileController`                 |

## 贡献

欢迎贡献！

如果你觉得少了某个钩子，别多想直接开个 Pull Request ～

为了合并新的自定义钩子，你需要按如下规则办事：

- 介绍使用例

  开个 issue 解释一下为什么我们需要这个钩子，怎么用它……\
  这很重要，如果这个钩子对很多人没有吸引力，那么它就不会被合并。

  如果你被拒了也没关系！这并不意味着以后也被拒绝，如果越来越多的人感兴趣。\
  在这之前，你也可以把你的钩子发布到 [pub](https://pub.dev/) 上～

- 为你的钩子写测试

  除非钩子被完全测试好，不然不会合并，以防未来不经意破坏了它也没法发现。

- 把它加到 README 并写介绍

## 赞助

<p align="center">
  <a href="https://raw.githubusercontent.com/rrousselGit/freezed/master/sponsorkit/sponsors.svg">
    <img src='https://raw.githubusercontent.com/rrousselGit/freezed/master/sponsorkit/sponsors.svg'/>
  </a>
</p>
