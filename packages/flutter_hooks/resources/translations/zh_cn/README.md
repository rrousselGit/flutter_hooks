[English](https://github.com/rrousselGit/flutter_hooks/blob/master/README.md) | [Português](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/pt_br/README.md) | [한국어](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/ko_kr/README.md) | [简体中文](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/zh_cn/README.md) | [日本語](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/ja_jp/README.md)

[![Build](https://github.com/rrousselGit/flutter_hooks/workflows/Build/badge.svg)](https://github.com/rrousselGit/flutter_hooks/actions?query=workflow%3ABuild) [![codecov](https://codecov.io/gh/rrousselGit/flutter_hooks/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/flutter_hooks) [![pub package](https://img.shields.io/pub/v/flutter_hooks.svg)](https://pub.dev/packages/flutter_hooks) [![pub package](https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square)](https://github.com/Solido/awesome-flutter)

<a href="https://discord.gg/GSt793j6eT"><img src="https://img.shields.io/discord/765557403865186374.svg?logo=discord&color=blue" alt="Discord"></a>

<p align="center">
  <img src="https://raw.githubusercontent.com/rrousselGit/flutter_hooks/master/packages/flutter_hooks/flutter-hook.svg?sanitize=true" width="200">
</p>

# Flutter Hooks

这是一个 React Hooks 在 Flutter 中的实现：[Making Sense of React Hooks](https://medium.com/@dan_abramov/making-sense-of-react-hooks-fdbde8803889)

Hooks 是一种管理 `Widget` 生命周期的新对象，以减少重复代码、增加组件间复用性。

## 动机

`StatefulWidget` 存在一个大问题：很难重用 `initState` 或 `dispose` 的逻辑，一个典型的例子就是 `AnimationController`：

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

Dart 的 mixin 能部分解决这个问题，但它们也存在其他问题：

- 一个给定的 mixin 在每个类中只能使用一次。
- Mixin 和类共用一个对象。\
  这意味着如果两个 mixin 定义了同名变量，结果要么是编译失败，要么引起未知行为。

---

本库提供了另一个解决方法：

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

这段代码在功能上等同于前面的例子。\
它仍然会在适当的时候 dispose `AnimationController`，并在 `Example.duration` 改变时仍会更新其 `duration`。

但你可能会想：

> 所有逻辑都去哪了？

这些逻辑已经被移到了 `useAnimationController` 中，这是本库中直接包含的一个函数（参见 [现有 hooks](#已有的 Hook) ）————这就是我们所说的 _钩子_。

钩子是一种具有以下特定性质的新对象：

- 它们只能在混入 `Hooks` 的 widget 的 `build` 方法中使用。
- 同一个钩子可以任意多次重复使用。\
  以下代码定义了两个独立的 `AnimationController`，并且都在 widget 重建时能正确保留它们。

  ```dart
  Widget build(BuildContext context) {
    final controller = useAnimationController();
    final controller2 = useAnimationController();
    return Container();
  }
  ```

- 钩子彼此之间以及与 widget 完全独立。\
  这意味着它们可以轻松提取为包并在 [pub](https://pub.dev/) 上发布供他人使用。

## 原理

与 `State` 类似，钩子存储在 `Widget` 的 `Element` 中。但是，`Element` 存储的是 `List<Hook>` 而不是一个 `State`。\
要使用 `Hook`，必须调用 `Hook.use`。

通过 `use` 返回的钩子基于被调用的次数。\
第一次调用返回第一个钩子，第二次返回第二个钩子，第三次返回第三个钩子，以此类推。

如果这个概念还不清楚，钩子的简单实现可能如下所示：

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

有关 hooks 实现的更多解释，这里有一篇关于 React 中如何实现的 [文章](https://medium.com/@ryardley/react-hooks-not-magic-just-arrays-cd4f1857236e)。

## 规则

由于钩子通过它们的 index 保留，因此必须遵守一些规则：

### _要_ 始终以 `use` 作为钩子的前缀

```dart
Widget build(BuildContext context) {
  // 以 `use` 开头，非常好的名字
  useMyHook();
  // 不以 `use` 开头，可能让人误以为这不是一个 hook
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

### _不要_ 将 `use` 包在条件语句中

```dart
Widget build(BuildContext context) {
  if (condition) {
    useMyHook();
  }
  // ....
}
```

---

### 关于热重载

由于钩子通过它们的 index 保留，可能有人认为在重构时热重载会搞崩程序。

但不用担心，`HookWidget` 会覆盖默认的热重载行为以适配 hooks。不过，在某些情况下钩子的状态可能会被重置。

设想如下三个钩子：

```dart
useA();
useB(0);
useC();
```

接下来，我们在热重载后修改 `HookB` 的参数：

```dart
useA();
useB(42);
useC();
```

这里一切正常，所有的钩子都保留了它们的状态。

现在再删掉 `HookB` 试试：

```dart
useA();
useC();
```

在这种情况下，`HookA` 会保留它的状态，但 `HookC` 会被强制重置。\
这是因为当重构后执行热重载时，在第一个被影响的钩子 _之后_ 的所有钩子都会被 dispose 掉。\
因此，由于 `HookC` 放在 `HookB` _之后_，所以它会被 dispose 掉。

## 如何创建钩子

这有两种方法：

- 函数式钩子

  函数是目前用来写钩子的最常用方法。\
  得益于钩子天然的可组合性，函数能够组合其他钩子来创建更复杂的自定义钩子。\
  按照惯例，这些函数将以 `use` 为前缀。

  如下代码构建了一个自定义钩子，其创建了一个变量，并在值改变时将其打印到控制台：

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

  当一个钩子变得过于复杂时，可以将其转化为一个继承 `Hook` 的类——然后可以通过 `Hook.use` 使用。\
  作为一个类，钩子看起来和 `State` 类差不多，并且可以访问 widget 生命周期和方法，比如 `initHook`、`dispose`和`setState`。

  通常的做法是将类隐藏在函数之下，如下所示：

  ```dart
  Result useMyHook() {
    return use(const _TimeAlive());
  }
  ```

  如下代码构建了一个自定义钩子，它在被 dispose 时打印其状态存活的总时长。

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

## 现有 Hooks

Flutter_Hooks 已经附带了一系列可重用的 hooks，它们分为不同的种类：

### 基础类别

一组与 widget 不同生命周期交互的低级钩子。

| 名称                                                                                                     | 描述                                         |
| -------------------------------------------------------------------------------------------------------- | -------------------------------------------- |
| [useEffect](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useEffect.html)             | 用于处理副作用，并可选择性地进行清理       |
| [useState](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useState.html)               | 创建一个变量并订阅它的变化                 |
| [useMemoized](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useMemoized.html)         | 缓存复杂对象的实例                         |
| [useRef](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useRef.html)                   | 创建一个包含单个可变属性的对象           |
| [useCallback](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useCallback.html)         | 缓存函数实例                               |
| [useContext](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useContext.html)           | 获取当前 `HookWidget` 的 `BuildContext`    |
| [useValueChanged](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useValueChanged.html) | 监听某个值的变化，并在值发生变化时触发回调 |

### 对象绑定（Object-binding）

这类钩子用于操作现有的 Flutter 及 Dart 对象\
它们负责创建、更新以及 dispose 对象

#### dart:async 相关

| 名称                                                                                                             | 描述                                                       |
| ---------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| [useStream](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useStream.html)                     | 订阅一个 `Stream` 并返回其当前状态（`AsyncSnapshot`）    |
| [useStreamController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useStreamController.html) | 创建一个 `StreamController`，会在不再使用时自动释放      |
| [useOnStreamChange](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useOnStreamChange.html)     | 订阅 `Stream`，注册处理函数，并返回 `StreamSubscription` |
| [useFuture](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useFuture.html)                     | 订阅一个 `Future` 并返回其当前状态（`AsyncSnapshot`）    |

#### Animation 相关

| 名称                                                                                                                     | 描述                                       |
| ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------ |
| [useSingleTickerProvider](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useSingleTickerProvider.html) | 创建单次使用的 `TickerProvider`          |
| [useAnimationController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useAnimationController.html)   | 创建并会自动释放的 `AnimationController` |
| [useAnimation](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useAnimation.html)                       | 订阅一个 `Animation` 并返回其当前值      |

#### Listenable 相关

| 名称                                                                                                                 | 描述                                                  |
| -------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| [useListenable](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useListenable.html)                 | 订阅一个 `Listenable`，当回调触发时标记组件需要重建 |
| [useListenableSelector](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useListenableSelector.html) | 类似于 `useListenable`，但允许过滤 UI 重建          |
| [useValueNotifier](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useValueNotifier.html)           | 创建一个 `ValueNotifier`，并在不再使用时自动释放    |
| [useValueListenable](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useValueListenable.html)       | 订阅一个 `ValueListenable` 并返回其值               |
| [useOnListenableChange](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useOnListenableChange.html) | 为 `Listenable` 添加回调，并在不再需要时自动移除    |

#### 杂项

一组无明确主题的钩子

| 名称                                                                                                                                   | 描述                                                                                           |
| -------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| [useReducer](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useReducer.html)                                         | `useState` 的替代方案，适用于更复杂的状态管理                                                |
| [usePrevious](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/usePrevious.html)                                       | 返回上一次调用 `usePrevious` 时的参数                                                        |
| [useTextEditingController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useTextEditingController-constant.html)    | 创建一个 `TextEditingController`                                                             |
| [useFocusNode](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useFocusNode.html)                                     | 创建一个 `FocusNode`                                                                         |
| [useTabController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useTabController.html)                             | 创建并自动释放一个 `TabController`                                                           |
| [useScrollController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useScrollController.html)                       | 创建并自动释放一个 `ScrollController`                                                        |
| [usePageController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/usePageController.html)                           | 创建并自动释放一个 `PageController`                                                          |
| [useFixedExtentScrollController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useFixedExtentScrollController.html) | 创建并自动释放一个 `FixedExtentScrollController`                                             |
| [useAppLifecycleState](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useAppLifecycleState.html)                     | 返回当前的 `AppLifecycleState`，并在其变化时触发组件重建                                     |
| [useOnAppLifecycleStateChange](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useOnAppLifecycleStateChange.html)     | 监听 `AppLifecycleState` 的变化，并在变化时触发回调                                          |
| [useTransformationController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useTransformationController.html)       | 创建并自动释放一个 `TransformationController`                                                |
| [useIsMounted](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useIsMounted.html)                                     | Hook 版本的 `State.mounted`                                                                  |
| [useAutomaticKeepAlive](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useAutomaticKeepAlive.html)                   | Hook 版本的 `AutomaticKeepAlive` 组件                                                        |
| [useOnPlatformBrightnessChange](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useOnPlatformBrightnessChange.html)   | 监听平台亮度（`Brightness`）变化，并在变化时触发回调                                         |
| [useSearchController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useSearchController.html)                       | 创建并自动释放一个 `SearchController`                                                        |
| [useWidgetStatesController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useWidgetStatesController.html)           | 创建并自动释放一个 `WidgetStatesController`                                                  |
| [useExpansibleController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useExpansibleController.html)               | 创建一个 `ExpansibleController`                                                              |
| [useDebounced](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useDebounced.html)                                     | 返回一个防抖后的值，在指定延时后触发更新                                                     |
| [useDraggableScrollableController](https://api.flutter.dev/flutter/widgets/DraggableScrollableController-class.html)                   | 创建一个 `DraggableScrollableController`                                                     |
| [useCarouselController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useCarouselController.html)                   | 创建并自动释放一个 `CarouselController`                                                      |
| [useTreeSliverController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useTreeSliverController.html)               | 创建一个 `TreeSliverController`                                                              |
| [useOverlayPortalController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useOverlayPortalController.html)         | 创建并管理一个 `OverlayPortalController`，用于控制覆盖层内容的可见性，会在不再需要时自动释放 |
| [useSnapshotController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useSnapshotController.html)                   | 创建并管理一个 `SnapshotController`                                                          |
| [useCupertinoController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useCupertinoController.html)                 | 创建并管理一个 `CupertinoController`                                                         |

## 贡献

欢迎贡献！

如果你觉得缺少某个钩子，可以随时发起 [Pull Request](https://github.com/rrousselGit/flutter_hooks/pulls) ～

为了合并新的自定义钩子，你需要按如下规则办事：

- 描述使用场景：

  发起一个 [issue](https://github.com/rrousselGit/flutter_hooks/issues) 解释为什么我们需要这个钩子，如何使用它等等。\
  这很重要，如果这个钩子对很多人没有吸引力，那么它就不会被合并。

  如果你被拒了也没关系！这并不意味着以后也被拒绝，如果越来越多的人感兴趣。\
  在这之前，你也可以把你的钩子发布到 [pub](https://pub.dev/) 上～

- 为你的钩子写测试：

  除非完全经过测试，否则钩子不会被合并，以防未来不经意破坏了它也没法发现。

- 将其添加到 README 并为其编写文档。

## 赞助

<p align="center">
  <a href="https://raw.githubusercontent.com/rrousselGit/freezed/master/sponsorkit/sponsors.svg">
    <img src='https://raw.githubusercontent.com/rrousselGit/freezed/master/sponsorkit/sponsors.svg'/>
  </a>
</p>
