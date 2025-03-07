[English](https://github.com/rrousselGit/flutter_hooks/blob/master/README.md) | [Português](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/pt_br/README.md) | [한국어](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/ko_kr/README.md) | [简体中文](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/zh_cn/README.md) | [日本語](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/ja_jp/README.md)

[![Build](https://github.com/rrousselGit/flutter_hooks/workflows/Build/badge.svg)](https://github.com/rrousselGit/flutter_hooks/actions?query=workflow%3ABuild) [![codecov](https://codecov.io/gh/rrousselGit/flutter_hooks/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/flutter_hooks) [![pub package](https://img.shields.io/pub/v/flutter_hooks.svg)](https://pub.dartlang.org/packages/flutter_hooks) [![pub package](https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square)](https://github.com/Solido/awesome-flutter)
<a href="https://discord.gg/6G6ZWkk3fQ"><img src="https://img.shields.io/discord/765557403865186374.svg?logo=discord&color=blue" alt="Discord"></a>

<img src="https://raw.githubusercontent.com/rrousselGit/flutter_hooks/master/packages/flutter_hooks/flutter-hook.svg?sanitize=true" width="200">

# 플러터 훅

리액트 훅을 플러터에서 구현했을때 생기는 일: https://medium.com/@dan_abramov/making-sense-of-react-hooks-fdbde8803889

훅은 `widget` 의 생명주기를 관리하는 새로운 종류의 객체입니다. 훅이 존재하는 이유: 중복을 제거함으로써 위젯간 코드 생산성을 증가시킵니다.

## 제작 동기

`StatefulWidget`은 아래와 같은 문제점이 있습니다: `initState` 나 `dispose`에서 사용된 로직을 재사용하기가 매우 어렵습니다. 적절한 예시는 `AnimationController`입니다:

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

`AnimationController` 를 사용하고 싶다면 사용하려는 모든 위젯에서 이 로직을 반복해야 합니다. 하지만 대부분 이를 원치 않을겁니다.

Dart Mixins 으로 이 문제를 해결할 수 있지만, 다른 문제점들이 있습니다:

- Mixin은 한 클래스 당 한번만 사용할 수 있습니다.
- Mixin 과 클래스는 같은 객체를 공유합니다.
  예를 들어 두개의 Mixin 이 같은 이름일 때, 컴파일 에러에서부터 알 수 없는 결과까지 다양한 결과를 가져올 수 있음을 의미합니다.

---

이 라이브러리는 세번째 해결책을 제안합니다:

```dart
class Example extends HookWidget {
  const Example({super.key, required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: duration);
    return Container();
  }
}
```

이 코드는 위 예제와 기능적으로 동일합니다. 여전히 `AnimationController` 를 dispose 하고, `Example.duration` 이 변경될 때 `duration` 을 업데이트합니다.
당신은 아마도 다음과 같은 생각을 하고 있을 것입니다:

> 다른 로직들은 어디에 있지?

그 로직들은 `useAnimationController` 함수로 옮겨 졌습니다. 이 함수는 이 라이브러리에 내장되어 있습니다. ( [기본적인 훅들](https://github.com/rrousselGit/flutter_hooks#existing-hooks) 보기) - 이것이 훅 입니다.

훅은 몇가지의 특별함(Sepcification)을 가지고 있는 새로운 종류의 객체입니다.

- Mixin한 위젯의 `build` 메소드 안에서만 사용할 수 있습니다.
- 동일한 훅이라도 여러번 재사용될 수 있습니다. 아래에는 두개의 `AnimationController` 가 있습니다. 각각의 훅은 위젯이 리빌드 될 때 다른 훅의 상태를 보존합니다:

  ```dart
  Widget build(BuildContext context) {
    final controller = useAnimationController();
    final controller2 = useAnimationController();
    return Container();
  }
  ```

- 훅과 훅, 훅과 위젯은 완전하게 독립적입니다.
  이것은 훅을 패키지로 추출하고 [pub](https://pub.dartlang.org/) 에서 다른 사람들이 사용할 수 있도록 쉽게 만들어 줍니다.

## 원리

`State`와 유사한 점은, 훅은 `Element` 라는 `Widget` 에 저장됩니다. 다른 점은 `State` 하나만 갖는 것 대신에, `Element`는 `List<Hook>`에 저장합니다. 그리고 훅을 사용하기 위해서는 `Hook.use`이라고 호출합니다.

`use` 함수에 의해 반환된 훅은 `use`가 호출된 횟수에 기반합니다.
첫번째 호출은 첫번째 훅을 반환하고, 두번째 호출은 두번째 훅을 반환하고, 세번째 호출은 세번째 훅을 반환하며 이런식으로 진행됩니다.

만약 이 개념이 이해가 안된다면, 아래를 보고 훅이 어떻게 구현되었는지 확인해보세요:

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

## 규칙

훅은 리스트안에 존재하고, 인덱스로 불러오기 때문에, 몇가지 규칙을 지켜야합니다.:

### 이름을 지을 때는 `use` 로 시작하시오:

```dart
Widget build(BuildContext context) {
  // `use`로 시작했다면, 굿입니다.
  useMyHook();
  // `use`로 시작하지 않기 때문에, 훅을 사용하는 사람들 사이에서 헷갈릴 수 있습니다.
  myHook();
  // ....
}
```

### 조건문 없이 호출하시오:

```dart
Widget build(BuildContext context) {
  useMyHook();
  // ....
}
```

### `use`를 조건문 안에 넣지 마시오:

```dart
Widget build(BuildContext context) {
  if (condition) {
    useMyHook();
  }
  // ....
}
```

---

### 핫리로드에 대해서

훅은 인덱스로부터 얻어지기 때문에, 코드를 수정 하고 핫 리로드를 실행하면 앱이 멈춘다고 생각할 수도 있습니다.

걱정하지 마세요, `HookWidget` 은 핫 리로드 시에도 훅의 상태들이 유지될 수 있도록 재정의 합니다.. 그럼에도, 훅의 상태가 리셋될 수 있는 상황이 있습니다.

아래의 훅 리스트를 보세요:

```dart
useA();
useB(0);
useC();
```

그 다음, 핫 리로드가 실행 된 후에 `HookB` 의 값을 수정했다고 가정해봅시다:

```dart
useA();
useB(42);
useC();
```

모든 훅이 잘 작동하고, 모든 훅의 상태가 유지됩니다.

이제 `HookB`가 제거해 봅시다. 그러면:

```dart
useA();
useC();
```

이 상황에서 `HookA` 는 상태를 유지하지만 `HookC` 는 리셋됩니다.
이유는 코드를 수정 한 후 핫 리로드가 실행되면, 첫번째로 영향을 받은 행 이후의 모든 훅이 제거되기 때문입니다.
그래서 `HookC` 는 `HookB` 뒤에 있기 때문에 상태가 리셋됩니다.

## 훅을 생성하는 법

훅을 생성하기위한 두가지 방법이 있습니다:

- 함수

  함수는 훅을 작성하는 가장 일반적인 방법입니다. 훅이 자연스럽게 합성 가능한 덕분에, 함수는 다른 훅을 결합하여 더 복잡한 커스텀 훅을 만들 수 있습니다. 관례상, 이러한 함수는 `use`로 시작됩니다.

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

  훅이 너무 복잡해지면, `Hook` 을 확장하는 클래스로 변환할 수 있습니다. 이 클래스는 `Hook.use` 함수로 사용할 수 있습니다.
  클래스로 훅을 정의하면, 훅은 `State` 클래스와 매우 유사하게 보일 것이며 `initHook`, `dispose` 및 `setState`와 같은 위젯의 라이프 사이클 및 메서드에 액세스 할 수 있습니다.

  이와같이 함수 내에 클래스를 숨기는것은 좋은 예시입니다:

  ```dart
  Result useMyHook() {
    return use(const _TimeAlive());
  }
  ```

  아래의 코드는 `State`가 생성되있었던 시간을 콘솔에 출력하는 훅을 정의합니다:

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

## 기본적인 훅들

Flutter_Hooks 는 이미 재사용 가능한 훅 목록을 제공합니다. 이 목록은 다음과 같이 구분됩니다:

### 원시적

다른 위젯의 생명주기에 반응하는 기초적인 훅 입니다.

| Name                                                                                                              | Description                                                  |
| ----------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| [useEffect](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useEffect.html)             | 상태를 업데이트하거나 선택적으로 취소하기에 유용합니다.      |
| [useState](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useState.html)               | 변수를 생성하고 구독합니다.                                  |
| [useMemoized](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useMemoized.html)         | 다양한 객체의 인스턴스를 캐싱합니다.                         |
| [useRef](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useRef.html)                   | 하나의 프로퍼티를 포함하는 객체를 만듭니다.                  |
| [useCallback](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useCallback.html)         | 함수의 인스턴스를 캐싱합니다.                                |
| [useContext](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useContext.html)           | `HookWidget` 의 `BuildContext`를 가져옵니다.                 |
| [useValueChanged](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useValueChanged.html) | 값을 모니터링하고, 값이 변경될 때마다 콜백함수를 실행합니다. |

### 객체 바인딩

해당 훅들은 Flutter/Dart에 이미 존재하는 객체들을 조작합니다.
이 훅은 객체를 생성/업데이트/삭제하는 역할을 합니다.

#### dart:async 와 관련된 훅:

| Name                                                                                                                      | Description                                                        |
| ------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| [useStream](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useStream.html)                     | `Stream`을 구독합니다. `AsyncSnapshot`으로 현재 상태를 반환합니다. |
| [useStreamController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useStreamController.html) | 알아서 dispose되는 `StreamController` 를 생성합니다.               |
| [useFuture](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useFuture.html)                     | `Future`를 구독합니다. `AsyncSnapshot`으로 상태를 반환합니다.      |

#### Animation 에 관련된 훅:

| Name                                                                                                                              | Description                                                |
| --------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| [useSingleTickerProvider](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useSingleTickerProvider.html) | `TickerProvider`를 생성합니다.                             |
| [useAnimationController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useAnimationController.html)   | 자동으로 dispose 되는 `AnimationController`를 생성합니다.  |
| [useAnimation](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useAnimation.html)                       | `Animation` 를 구독합니다. 해당 객체의 value를 반환합니다. |

#### Listenable 에 관련된 훅:

| Name                                                                                                                          | Description                                                                                |
| ----------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| [useListenable](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useListenable.html)                 | `Listenable` 을 구독합니다. 리스너가 호출될 때마다 위젯을 빌드가 필요한 것으로 표시합니다. |
| [useListenableSelector](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useListenableSelector.html) | Similar to `useListenable` 과 비슷하지만, 원하는 위젯만 변경되도록 선택할 수 있습니다..    |
| [useValueNotifier](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useValueNotifier.html)           | 자동적으로 dispose 되는 `ValueNotifier`를 생성합니다.                                      |
| [useValueListenable](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useValueListenable.html)       | `ValueListenable` 를 구독합니다. 그 값을 반환합니다..                                      |

#### 기타 훅:

특별한 특징이 없는 훅들입니다.

| Name                                                                                                                                          | Description                                                                  |
| --------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| [useReducer](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useReducer.html)                                       | state가 조금 더 복잡할 때, `useState` 대신 사용할 대안 입니다.               |
| [usePrevious](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/usePrevious.html)                                     | 바로 이전에 실행된 [usePrevious]의 값을 반환합니다.                          |
| [useTextEditingController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useTextEditingController-constant.html)           | `TextEditingController`를 생성합니다.                                        |
| [useFocusNode](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useFocusNode.html)                                   | `FocusNode`를 생성합니다.                                                    |
| [useTabController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useTabController.html)                           | `TabController`를 생성합니다.                                                |
| [useScrollController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useScrollController.html)                     | `ScrollController`를 생성합니다.                                             |
| [usePageController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/usePageController.html)                         | `PageController`를 생성합니다.                                               |
| [useAppLifecycleState](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useAppLifecycleState.html)                   | 현재 `AppLifecycleState`를 반환합니다. 그리고 변화된 위젯을 다시 빌드합니다. |
| [useOnAppLifecycleStateChange](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useOnAppLifecycleStateChange.html)   | Listens to `AppLifecycleState`가 변경될 때, 콜백함수를 실행합니다.           |
| [useTransformationController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useTransformationController.html)     | Creates and disposes a `TransformationController`를 생성합니다.              |
| [useIsMounted](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useIsMounted.html)                                   | `State.mounted` 와 동일한 기능의 훅입니다.                                   |
| [useAutomaticKeepAlive](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useAutomaticKeepAlive.html)                 | `AutomaticKeepAlive`와 동일한 훅입니다.                                      |
| [useOnPlatformBrightnessChange](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useOnPlatformBrightnessChange.html) | 플랫폼의 `Brightness` 이 변경될 때, 콜백함수를 실행합니다.                   |

## Contributions

기부를 환영합니다!

후크가 없는 것 같으면 풀 요청을 여십시오.

사용자 지정 후크를 병합하려면 다음을 수행해야 합니다:

- 사용 사례를 설명합니다.

  이 후크가 왜 필요한지, 어떻게 사용하는지 설명하는 문제를 엽니다...
  훅이 매력적이지 않으면 후크가 병합되지 않기 때문에 이것은 중요합니다
  많은 사람들.

  만약 여러분의 훅이 거절당하더라도, 걱정하지 마세요! 거절한다고 해서 거절당하지는 않을 것이다
  더 많은 사람들이 그것에 관심을 보이면 나중에 합병된다.
  그동안 https://pub.dev에 당신의 후크를 패키지로 게시하세요.

- 후크에 대한 테스트 쓰기

  후크가 실수로 파손되지 않도록 완전히 테스트하지 않는 한 후크는 병합되지 않습니다
  미래에.

- README에 추가하고 해당 문서를 작성합니다.

## Sponsors

<p align="center">
  <a href="https://raw.githubusercontent.com/rrousselGit/freezed/master/sponsorkit/sponsors.svg">
    <img src='https://raw.githubusercontent.com/rrousselGit/freezed/master/sponsorkit/sponsors.svg'/>
  </a>
</p>
