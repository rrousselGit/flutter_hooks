A package that contains utilities for using [mobx](https://pub.dev/packages/mobx) using the hook syntax

## Usage

This package offers 4 utilities: 

- `useAutorun`
- `useObserver`
- `useReaction`
- `useWhen`

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
