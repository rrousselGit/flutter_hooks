[English](https://github.com/rrousselGit/flutter_hooks/blob/master/README.md) | [Português](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/pt_br/README.md) | [한국어](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/ko_kr/README.md) | [简体中文](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/zh_cn/README.md) | [日本語](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/ja_jp/README.md)

[![Build](https://github.com/rrousselGit/flutter_hooks/workflows/Build/badge.svg)](https://github.com/rrousselGit/flutter_hooks/actions?query=workflow%3ABuild) [![codecov](https://codecov.io/gh/rrousselGit/flutter_hooks/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/flutter_hooks) [![pub package](https://img.shields.io/pub/v/flutter_hooks.svg)](https://pub.dev/packages/flutter_hooks) [![pub package](https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square)](https://github.com/Solido/awesome-flutter)
<a href="https://discord.gg/6G6ZWkk3fQ"><img src="https://img.shields.io/discord/765557403865186374.svg?logo=discord&color=blue" alt="Discord"></a>

<img src="https://raw.githubusercontent.com/rrousselGit/flutter_hooks/master/packages/flutter_hooks/flutter-hook.svg?sanitize=true" width="200">

# Flutter Hooks

React hooksのFlutter実装: https://medium.com/@dan_abramov/making-sense-of-react-hooks-fdbde8803889

Hooksは、`Widget`のライフサイクルを管理する新しい種類のオブジェクトです。これらは、ウィジェット間のコード共有を増やし、重複を排除するために存在します。

## 動機

`StatefulWidget`には大きな問題があります。それは、`initState`や`dispose`のロジックを再利用するのが非常に難しいことです。明らかな例は`AnimationController`です：

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

`AnimationController`を使用したいすべてのウィジェットは、このロジックのほとんどを最初から再実装する必要があります。これはもちろん望ましくありません。

Dartのミックスインはこの問題を部分的に解決できますが、他の問題も抱えています：

- 特定のミックスインはクラスごとに1回しか使用できません。
- ミックスインとクラスは同じオブジェクトを共有します。\
  これは、2つのミックスインが同じ名前の変数を定義した場合、結果がコンパイルエラーから未知の動作までさまざまであることを意味します。

---

このライブラリは第三の解決策を提案します：

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

このコードは前の例と機能的に同等です。`AnimationController`をdisposeし、`Example.duration`が変更されたときにその`duration`を更新します。
しかし、あなたはおそらくこう思っているでしょう：

> すべてのロジックはどこに行ったのですか？

そのロジックは、このライブラリに直接含まれている関数`useAnimationController`に移動されました（[既存のフック](https://github.com/rrousselGit/flutter_hooks#existing-hooks)を参照）。これが私たちが呼ぶ_Hook_です。

Hooksは、いくつかの特性を持つ新しい種類のオブジェクトです：

- それらは、`Hooks`をミックスインしたウィジェットの`build`メソッドでのみ使用できます。
- 同じフックを任意の回数再利用できます。
  次のコードは、2つの独立した`AnimationController`を定義し、ウィジェットが再構築されるときに正しく保持されます。

  ```dart
  Widget build(BuildContext context) {
    final controller = useAnimationController();
    final controller2 = useAnimationController();
    return Container();
  }
  ```

- フックは互いに完全に独立しており、ウィジェットからも独立しています。\
  これは、それらを簡単にパッケージに抽出し、他の人が使用できるように[pub](https://pub.dev/)に公開できることを意味します。

## 原則

`State`と同様に、フックは`Widget`の`Element`に保存されます。ただし、1つの`State`を持つ代わりに、`Element`は`List<Hook>`を保存します。次に、`Hook`を使用するためには、`Hook.use`を呼び出す必要があります。

`use`によって返されるフックは、呼び出された回数に基づいています。
最初の呼び出しは最初のフックを返し、2回目の呼び出しは2番目のフックを返し、3回目の呼び出しは3番目のフックを返します。

このアイデアがまだ不明確な場合、フックの単純な実装は次のようになります：

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

フックがどのように実装されているかについての詳細な説明については、Reactでの実装方法に関する素晴らしい記事があります：https://medium.com/@ryardley/react-hooks-not-magic-just-arrays-cd4f1857236e

## 規則

フックがそのインデックスから取得されるため、いくつかの規則を守る必要があります：

### フックの名前を常に`use`で始める：

```dart
Widget build(BuildContext context) {
  // `use`で始まる、良い名前
  useMyHook();
  // `use`で始まらない、これはフックではないと誤解される可能性があります
  myHook();
  // ....
}
```

### フックを無条件に呼び出す

```dart
Widget build(BuildContext context) {
  useMyHook();
  // ....
}
```

### `use`を条件にラップしない

```dart
Widget build(BuildContext context) {
  if (condition) {
    useMyHook();
  }
  // ....
}
```

---

### ホットリロードについて

フックがそのインデックスから取得されるため、リファクタリング中のホットリロードがアプリケーションを壊すと考えるかもしれません。

しかし心配しないでください、`HookWidget`はフックで動作するようにデフォルトのホットリロード動作をオーバーライドします。それでも、フックの状態がリセットされる場合があります。

次のフックのリストを考えてみましょう：

```dart
useA();
useB(0);
useC();
```

次に、ホットリロードを実行した後に`HookB`のパラメータを編集したと考えます：

```dart
useA();
useB(42);
useC();
```

ここではすべてが正常に動作し、すべてのフックがその状態を保持します。

次に、`HookB`を削除したと考えます。次のようになります：

```dart
useA();
useC();
```

この場合、`HookA`はその状態を保持しますが、`HookC`はハードリセットされます。
これは、リファクタリング後にホットリロードが実行されると、最初の影響を受けた行の後のすべてのフックがdisposeされるためです。
したがって、`HookC`が`HookB`の後に配置されていたため、disposeされます。

## フックの作成方法

フックを作成する方法は2つあります：

- 関数

  関数はフックを書く最も一般的な方法です。フックが本質的に合成可能であるため、関数は他のフックを組み合わせてより複雑なカスタムフックを作成できます。慣例として、これらの関数は`use`で始まります。

  次のコードは、変数を作成し、その値が変更されるたびにコンソールにログを記録するカスタムフックを定義します：

  ```dart
  ValueNotifier<T> useLoggedState<T>([T initialData]) {
    final result = useState<T>(initialData);
    useValueChanged(result.value, (_, __) {
      print(result.value);
    });
    return result;
  }
  ```

- クラス

  フックが複雑すぎる場合は、`Hook`を拡張するクラスに変換することができます。これを使用して`Hook.use`を使用できます。\
  クラスとして、フックは`State`クラスと非常に似ており、ウィジェットのライフサイクルや`initHook`、`dispose`、`setState`などのメソッドにアクセスできます。

  通常、クラスを次のように関数の下に隠すのが良いプラクティスです：

  ```dart
  Result useMyHook() {
    return use(const _TimeAlive());
  }
  ```

  次のコードは、`State`が生存していた合計時間をそのdispose時に出力するフックを定義します。

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

## 既存のフック

Flutter_Hooksには、再利用可能なフックのリストが既に含まれており、さまざまな種類に分かれています：

### プリミティブ

ウィジェットのさまざまなライフサイクルと対話する低レベルのフックのセット

| 名前                                                                                                     | 説明                                                                 |
| -------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| [useEffect](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useEffect.html)             | 副作用に役立ち、オプションでそれらをキャンセルします。              |
| [useState](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useState.html)               | 変数を作成し、それを購読します。                                    |
| [useMemoized](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useMemoized.html)         | 複雑なオブジェクトのインスタンスをキャッシュします。                |
| [useRef](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useRef.html)                   | 単一の可変プロパティを含むオブジェクトを作成します。                |
| [useCallback](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useCallback.html)         | 関数インスタンスをキャッシュします。                                |
| [useContext](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useContext.html)           | ビルド中の`HookWidget`の`BuildContext`を取得します。                |
| [useValueChanged](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useValueChanged.html) | 値を監視し、その値が変更されるたびにコールバックをトリガーします。 |

### オブジェクトバインディング

このカテゴリのフックは、既存のFlutter/Dartオブジェクトをフックで操作します。
それらはオブジェクトの作成/更新/破棄を担当します。

#### dart:async関連のフック：

| 名前                                                                                                             | 説明                                                                                 |
| ---------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| [useStream](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useStream.html)                     | `Stream`を購読し、その現在の状態を`AsyncSnapshot`として返します。                    |
| [useStreamController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useStreamController.html) | 自動的に破棄される`StreamController`を作成します。                                  |
| [useOnStreamChange](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useOnStreamChange.html)     | `Stream`を購読し、ハンドラを登録し、`StreamSubscription`を返します。                |
| [useFuture](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useFuture.html)                     | `Future`を購読し、その現在の状態を`AsyncSnapshot`として返します。                    |

#### アニメーション関連のフック：

| 名前                                                                                                                     | 説明                                                                 |
| ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------- |
| [useSingleTickerProvider](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useSingleTickerProvider.html) | 単一使用の`TickerProvider`を作成します。                            |
| [useAnimationController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useAnimationController.html)   | 自動的に破棄される`AnimationController`を作成します。               |
| [useAnimation](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useAnimation.html)                       | `Animation`を購読し、その値を返します。                              |

#### Listenable関連のフック：

| 名前                                                                                                                 | 説明                                                                                         |
| -------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| [useListenable](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useListenable.html)                 | `Listenable`を購読し、リスナーが呼び出されるたびにウィジェットをビルドが必要なものとしてマークします。 |
| [useListenableSelector](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useListenableSelector.html) | `useListenable`に似ていますが、UIの再構築をフィルタリングできます。                          |
| [useValueNotifier](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useValueNotifier.html)           | 自動的に破棄される`ValueNotifier`を作成します。                                              |
| [useValueListenable](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useValueListenable.html)       | `ValueListenable`を購読し、その値を返します。                                                |
| [useOnListenableChange](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useOnListenableChange.html) | 指定されたリスナーコールバックを`Listenable`に追加し、自動的に削除されます。                  |

#### その他のフック：

特定のテーマを持たない一連のフック。

| 名前                                                                                                                                   | 説明                                                                                                                                                              |
| -------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [useReducer](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useReducer.html)                                         | より複雑な状態のための`useState`の代替。                                                                                                                          |
| [usePrevious](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/usePrevious.html)                                       | [usePrevious]に渡された前の引数を返します。                                                                                                                       |
| [useTextEditingController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useTextEditingController-constant.html)    | `TextEditingController`を作成します。                                                                                                                             |
| [useFocusNode](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useFocusNode.html)                                     | `FocusNode`を作成します。                                                                                                                                         |
| [useTabController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useTabController.html)                             | `TabController`を作成し、破棄します。                                                                                                                             |
| [useScrollController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useScrollController.html)                       | `ScrollController`を作成し、破棄します。                                                                                                                          |
| [usePageController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/usePageController.html)                           | `PageController`を作成し、破棄します。                                                                                                                            |
| [useFixedExtentScrollController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useFixedExtentScrollController.html) | `FixedExtentScrollController`を作成し、破棄します。                                                                                                               |
| [useAppLifecycleState](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useAppLifecycleState.html)                     | 現在の`AppLifecycleState`を返し、変更時にウィジェットを再構築します。                                                                                             |
| [useOnAppLifecycleStateChange](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useOnAppLifecycleStateChange.html)     | `AppLifecycleState`の変更を監視し、変更時にコールバックをトリガーします。                                                                                         |
| [useTransformationController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useTransformationController.html)       | `TransformationController`を作成し、破棄します。                                                                                                                  |
| [useIsMounted](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useIsMounted.html)                                     | フックのための`State.mounted`の同等物。                                                                                                                           |
| [useAutomaticKeepAlive](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useAutomaticKeepAlive.html)                   | フックのための`AutomaticKeepAlive`ウィジェットの同等物。                                                                                                           |
| [useOnPlatformBrightnessChange](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useOnPlatformBrightnessChange.html)   | プラットフォームの`Brightness`の変更を監視し、変更時にコールバックをトリガーします。                                                                               |
| [useSearchController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useSearchController.html)                       | `SearchController`を作成し、破棄します。                                                                                                                          |
| [useWidgetStatesController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useWidgetStatesController.html)           | `WidgetStatesController`を作成し、破棄します。                                                                                                                    |
| [useExpansionTileController](https://api.flutter.dev/flutter/material/ExpansionTileController-class.html)                              | `ExpansionTileController`を作成します。                                                                                                                           |
| [useDebounced](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useDebounced.html)                                     | 指定されたタイムアウト期間後にウィジェットの更新をトリガーする、提供された値のデバウンスバージョンを返します。                                                     |
| [useDraggableScrollableController](https://api.flutter.dev/flutter/widgets/DraggableScrollableController-class.html)                   | `DraggableScrollableController`を作成します。                                                                                                                     |
| [useCarouselController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useCarouselController.html)                   | **`CarouselController`**を作成し、破棄します。                                                                                                                    |
| [useTreeSliverController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useTreeSliverController.html)               | `TreeSliverController`を作成します。                                                                                                                              |
| [useOverlayPortalController](https://api.flutter.dev/flutter/widgets/OverlayPortalController-class.html)                               | オーバーレイコンテンツの表示を制御するための`OverlayPortalController`を作成および管理します。コントローラーは、不要になったときに自動的に破棄されます。             |

## 貢献

貢献は歓迎されます！

フックが不足していると感じた場合は、プルリクエストを開いてください。

カスタムフックをマージするには、次のことを行う必要があります：

- 使用例を説明します。

  このフックがなぜ必要なのか、どのように使用するのかを説明する問題を開きます。...
  これは重要です。フックが多くの人にアピールしない場合、そのフックはマージされません。

  フックが拒否された場合でも心配しないでください！拒否されたからといって、将来的により多くの人が関心を示した場合にマージされないわけではありません。
  その間、https://pub.devにフックをパッケージとして公開してください。

- フックのテストを書く

  フックが将来誤って壊れるのを防ぐために、完全にテストされない限り、フックはマージされません。

- READMEに追加し、そのためのドキュメントを書く。

## スポンサー

<p align="center">
  <a href="https://raw.githubusercontent.com/rrousselGit/freezed/master/sponsorkit/sponsors.svg">
    <img src='https://raw.githubusercontent.com/rrousselGit/freezed/master/sponsorkit/sponsors.svg'/>
  </a>
</p>
