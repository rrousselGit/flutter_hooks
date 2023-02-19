[English](https://github.com/rrousselGit/flutter_hooks/blob/master/README.md) | [Português](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/pt_br/README.md) | [한국어](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/ko_kr/README.md)

[![Build](https://github.com/rrousselGit/flutter_hooks/workflows/Build/badge.svg)](https://github.com/rrousselGit/flutter_hooks/actions?query=workflow%3ABuild) [![codecov](https://codecov.io/gh/rrousselGit/flutter_hooks/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/flutter_hooks) [![pub package](https://img.shields.io/pub/v/flutter_hooks.svg)](https://pub.dartlang.org/packages/flutter_hooks) [![pub package](https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square)](https://github.com/Solido/awesome-flutter)
<a href="https://discord.gg/Bbumvej"><img src="https://img.shields.io/discord/765557403865186374.svg?logo=discord&color=blue" alt="Discord"></a>

<img src="https://raw.githubusercontent.com/rrousselGit/flutter_hooks/master/packages/flutter_hooks/flutter-hook.svg?sanitize=true" width="200">

# Flutter Hooks

A Flutter implementation of React hooks: https://medium.com/@dan_abramov/making-sense-of-react-hooks-fdbde8803889

훅은 `widget`의 라이프사이클을 관리하는 새로운 종류의 객체입니다.
훅은 한가지 이유로 존재합니다: 중복을 제거함으로써 위젯사이에 코드 공유를 증가시킵니다.

## Motivation

`StatefulWidget`는 아래와 같은 문제점이 있습니다: `initState`나 `dispose`와 같은 로직을 재사용하기가 매우 어렵습니다. 한가지 분명한 예시는 `AnimationController`입니다:

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

`AnimationController` 를 사용하는 모든 위젯은 이 로직을 재사용하기 위해 모두 이 로직을 재구현해야 합니다. 이는 물론 원치 않는 결과입니다.

Dart mixins 는 이 문제를 해결할 수 있지만, 다른 문제점들이 있습니다:
- 주어진 mixin 은 한 클래스당 한번만 사용할 수 있습니다.
- mixin 과 클래스는 같은 객체를 공유합니다.\
  이는 mixin 이 같은 이름의 변수를 정의하면, 컴파일 에러에서부터 알 수 없는 결과까지 다양한 결과를 가져올 수 있음을 의미합니다.

---

이 라이브러리는 세번째 해결책을 제안합니다:

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
이 코드는 이전 예제와 기능적으로 동일합니다. 여전히 `AnimationController` 를 dispose 하고, `Example.duration` 이 변경될 때 `duration` 을 업데이트합니다.
하지만 당신은 아마도 다음과 같은 생각을 하고 있을 것입니다:

> 모든 로직은 어디로 갔지?

이 로직은 `useAnimationController` 함수에 있습니다. 이 함수는 이 라이브러리에 포함되어 있습니다.
(see [Existing hooks](https://github.com/rrousselGit/flutter_hooks#existing-hooks)) - 이것이 우리가 훅이라고 부르는 것 입니다.

훅은 몇가지 사양(Sepcification)을 가지고 있는 새로운 종류의 객체입니다.

- 훅은 `Hooks` 를 mix-in 한 위젯의 `build` 메소드에서만 사용할 수 있습니다.
- 동일한 훅은 임의의 수만큼 재사용될 수 있습니다.
  아래 코드는 두개의 독립적인 `AnimationController` 를 정의합니다. 그리고 위젯이 리빌드 될 때 이것들이 올바르게 보존됩니다.

  ```dart
  Widget build(BuildContext context) {
    final controller = useAnimationController();
    final controller2 = useAnimationController();
    return Container();
  }
  ```
- 훅은 서로와 위젯에 완전히 독립적입니다.
  이것은 훅을 패키지로 추출하고 [pub](https://pub.dartlang.org/) 에서 다른 사람들이 사용할 수 있도록 쉽게 만들어 줍니다.

## Principle

`State`와 비슷하게 훅은 `Widget`의 `Element`에 저장됩니다. 그러나 `State` 하나만 갖는 것 대신에, `Element`는 `List<Hook>`를 갖습니다. 그리고 훅을 사용하기 위해서는 `Hook.use`를 호출해야 합니다.

`use` 함수에 의해 반환된 훅은 `use`가 호출된 횟수에 기반합니다.
첫번째 호출은 첫번째 훅을 반환하고, 두번째 호출은 두번째 훅을 반환하고, 세번째 호출은 세번째 훅을 반환하며 이런식으로 진행됩니다.

만약 이 아이디어가 아직도 이해가 안된다면, 아래와 같이 훅을 구현하는 것이 가능합니다:


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

훅을 구현하는 더 다양한 예시를 보기위해 React 에서 훅이 어떻게 구현되어 있는지 훌륭한 글이 있습니다: https://medium.com/@ryardley/react-hooks-not-magic-just-arrays-cd4f1857236e

## Rules

훅이 인덱스로부터 얻어지기 때문에, 몇가지 규칙을 지켜야 합니다:

### `use` 로 시작하는 이름을 사용하세요:

```dart
Widget build(BuildContext context) {
  // starts with `use`, good name
  useMyHook();
  // doesn't start with `use`, could confuse people into thinking that this isn't a hook
  myHook();
  // ....
}
```

### 훅을 조건 없이 호출하세요

```dart
Widget build(BuildContext context) {
  useMyHook();
  // ....
}
```

### `use`를 조건문 안에 넣지 마세요

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

훅은 인덱스로부터 얻어지기 때문에, 리팩토링을 하면서 핫 리로드가 어플리케이션을 깨뜨릴 수 있을 것 같다고 생각할 수 있습니다.

하지만 걱정하지 마세요, `HookWidget` 은 기본 핫 리로드 동작을 훅과 함께 작동하도록 재정의합니다. 그래도, 훅의 상태가 리셋될 수 있는 상황이 있습니다.

아래의 훅 리스트를 생각해보세요:


```dart
useA();
useB(0);
useC();
```

그런다음 hot-reload를 수행한 뒤 `HookB` 의 파라미터를 편집했다고 가정해봅시다:


```dart
useA();
useB(42);
useC();
```

모든 훅이 잘 작동하고, 모든 훅의 상태가 유지됩니다.

이제 `HookB`가 제거되었다고 생각해 봅시다. 우리는 이제 다음과 같은것을 가지게 됩니다:


```dart
useA();
useC();
```

이 상황에서 `HookA` 는 상태를 유지하지만 `HookC` 는 리셋됩니다.
이것은 리팩토링 후 핫 리로드를 수행하면, 첫번째로 영향을 받은 행 이후의 모든 훅이 제거되기 때문에 발생합니다.
그래서 `HookC`가 `HookB` 뒤에 있기 때문에 제거됩니다.

## How to create a hook

훅을 생성하기위한 두가지 방법이 있습니다:

- 함수
  함수는 훅을 작성하는 가장 일반적인 방법입니다. 훅이 자연스럽게 합성 가능하기 때문에, 함수는 다른 훅을 결합하여 더 복잡한 커스텀 훅을 만들 수 있습니다. 관례상, 이러한 함수는 `use`로 시작됩니다.

  아래의 코드는 변수를 생성하고, 값이 변경될 때마다 콘솔에 로그를 남기는 커스텀 훅을 정의합니다:

  ```dart
  ValueNotifier<T> useLoggedState<T>([T initialData]) {
    final result = useState<T>(initialData);
    useValueChanged(result.value, (_, __) {
      print(result.value);
    });
    return result;
  }
  ```

- 클래스

  훅이 너무 복잡해지면, `Hook` 을 확장하는 클래스로 변환할 수 있습니다. 이 클래스는 `Hook.use`를 사용하여 사용할 수 있습니다.
  클래스로 훅을 정의하면, 훅은 `State` 클래스와 매우 유사하게 보일 것이며 `initHook`, `dispose` 및 `setState`와 같은 위젯의 라이프 사이클 및 메서드에 액세스 할 수 있습니다.  

  이와같이 함수 내에 클래스를 숨기는것은 좋은 예시입니다:

  ```dart
  Result useMyHook() {
    return use(const _TimeAlive());
  }
  ```

  아래의 코드는 `State`가 얼마나 오래 살아있었는지 콘솔에 출력하는 훅을 정의합니다:

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

Flutter_Hooks 는 이미 재사용 가능한 훅 목록을 제공합니다. 이 목록은 다음과 같이 구분됩니다:

### Primitives

다른 위젯의 라이프사이클과 상호작용하는 low-level 의 훅 입니다.

| Name                                                                                                              | Description                                                         |
| ----------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| [useEffect](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useEffect.html)             | Useful for side-effects and optionally canceling them.              |
| [useState](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useState.html)               | Creates a variable and subscribes to it.                            |
| [useMemoized](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useMemoized.html)         | Caches the instance of a complex object.                            |
| [useRef](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useRef.html)                   | Creates an object that contains a single mutable property.          |
| [useCallback](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useCallback.html)         | Caches a function instance.                                         |
| [useContext](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useContext.html)           | Obtains the `BuildContext` of the building `HookWidget`.            |
| [useValueChanged](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useValueChanged.html) | Watches a value and triggers a callback whenever its value changed. |

### Object-binding

이 카테고리의 훅은 기존의 Flutter/Dart 객체를 조작합니다.
이 훅은 객체를 생성/업데이트/삭제하는 역할을 합니다.

#### dart:async related hooks:

| Name                                                                                                                      | Description                                                                   |
| ------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| [useStream](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useStream.html)                     | Subscribes to a `Stream` and returns its current state as an `AsyncSnapshot`. |
| [useStreamController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useStreamController.html) | Creates a `StreamController` which will automatically be disposed.            |
| [useFuture](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useFuture.html)                     | Subscribes to a `Future` and returns its current state as an `AsyncSnapshot`. |

#### Animation related hooks:

| Name                                                                                                                              | Description                                                            |
| --------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| [useSingleTickerProvider](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useSingleTickerProvider.html) | Creates a single usage `TickerProvider`.                               |
| [useAnimationController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useAnimationController.html)   | Creates an `AnimationController` which will be automatically disposed. |
| [useAnimation](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useAnimation.html)                       | Subscribes to an `Animation` and returns its value.                    |

#### Listenable related hooks:

| Name                                                                                                                          | Description                                                                                         |
| ----------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| [useListenable](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useListenable.html)                 | Subscribes to a `Listenable` and marks the widget as needing build whenever the listener is called. |
| [useListenableSelector](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useListenableSelector.html) | Similar to `useListenable`, but allows filtering UI rebuilds                                        |
| [useValueNotifier](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useValueNotifier.html)           | Creates a `ValueNotifier` which will be automatically disposed.                                     |
| [useValueListenable](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useValueListenable.html)       | Subscribes to a `ValueListenable` and return its value.                                             |

#### Misc hooks:

특정한 theme을 가지지 않는 일련의 훅 입니다.

| Name                                                                                                                                        | Description                                                                |
| ------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| [useReducer](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useReducer.html)                                     | An alternative to `useState` for more complex states.                      |
| [usePrevious](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/usePrevious.html)                                   | Returns the previous argument called to [usePrevious].                     |
| [useTextEditingController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useTextEditingController-constant.html)         | Creates a `TextEditingController`.                                         |
| [useFocusNode](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useFocusNode.html)                                 | Creates a `FocusNode`.                                                     |
| [useTabController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useTabController.html)                         | Creates and disposes a `TabController`.                                    |
| [useScrollController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useScrollController.html)                   | Creates and disposes a `ScrollController`.                                 |
| [usePageController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/usePageController.html)                       | Creates and disposes a `PageController`.                                   |
| [useAppLifecycleState](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useAppLifecycleState.html)                 | Returns the current `AppLifecycleState` and rebuilds the widget on change. |
| [useOnAppLifecycleStateChange](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useOnAppLifecycleStateChange.html) | Listens to `AppLifecycleState` changes and triggers a callback on change.  |
| [useTransformationController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useTransformationController.html)   | Creates and disposes a `TransformationController`.                         |
| [useIsMounted](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useIsMounted.html)                                 | An equivalent to `State.mounted` for hooks.                                |
| [useAutomaticKeepAlive](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useAutomaticKeepAlive.html)               | An equivalent to the `AutomaticKeepAlive` widget for hooks.                |
| [useOnPlatformBrightnessChange](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useOnPlatformBrightnessChange.html) | Listens to platform `Brightness` changes and triggers a callback on change.|

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
