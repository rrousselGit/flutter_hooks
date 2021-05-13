A package that contains utilities for using [mobx](https://pub.dev/packages/mobx) using the hook syntax

## Usage

`HookWidget`s can now use `useObserver` to listen to Mobx stores:


```dart
class Example extends HookWidget {

  @override
  Widget build(BuildContext context) {
    // cause the widget to rebuild when properties obtains from a mobx store changed
    useObserver();
  }
}

```