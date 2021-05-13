A package that contains utilities for using [mobx](https://pub.dev/packages/mobx) using the hook syntax

## Usage

This package offers 4 utilities: 

- `useAutorun`: to use Mobx [autorun](https://pub.dev/documentation/mobx/latest/mobx/autorun.html)
- `useObserver`: to use Mobx [observer](https://pub.dev/documentation/flutter_mobx/latest/flutter_mobx/Observer-class.html)
- `useReaction`: to use Mobx [reaction](https://pub.dev/documentation/mobx/latest/mobx/reaction.html)
- `useWhen`: to use Mobx [when](https://pub.dev/documentation/mobx/latest/mobx/when.html)

## autorun => useAutorun

Executes the specified callback, whenever the dependent observables change.

```dart
class Example extends HookWidget {

  @override
  Widget build(BuildContext context) {
    useAutorun((_) {
      final snackBar = SnackBar(content: Text('Yay! Counter have been hit ${myMobxStore.count} times!'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
    
    return Container();
  }
}
```

## Observer => useObserver

This hook will allow you to listen for Mobx store changes from your `HookWidget` or `HookBuilder`. 

Here is an example:

```dart
class Example extends HookWidget {

  @override
  Widget build(BuildContext context) {
    // cause the widget to rebuild when properties obtains from a mobx store changed
    useObserver();
    
    return Container(color: myMobxStore.color);
  }
}
```

## reaction => useReaction

Executes the callback function and tracks the observables used in it.

```dart
class Example extends HookWidget {

  @override
  Widget build(BuildContext context) {
    useReaction((_) {
      return myMobxStore.count*2;
    }, (value) {
      final snackBar = SnackBar(content: Text('$value is double of ${myMobxStore.count}'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
    
    return Container();
  }
}
```

## when => useWhen

A one-time reaction that auto-disposes when the predicate becomes true. It also executes the effect when the predicate turns true.

```dart
class Example extends HookWidget {

  @override
  Widget build(BuildContext context) {
    useWhen((_) {
      return myMobxStore.count == 5;
    }, () {
      final snackBar = SnackBar(content: Text('You\'ve reach the max count allowed (${myMobxStore.count})'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
    
    return Container();
  }
}
```

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

  A hook will not be merged unless fully tested, to avoid breaking it inadvertently
  in the future.

- Add it to the Readme & write documentation for it.
