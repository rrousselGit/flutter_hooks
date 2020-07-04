## 0.10.1

- Fix a bug where the order in which hooks are disposed is incorrect.

## 0.10.0

**Breaking change**:

- The order in which hooks are disposed has been reversed.

  Consider:

  ```dart
  useSomething();
  useSomethingElse();
  ```

  Before, the `useSomething` was disposed before `useSomethingElse`.
  Now, `useSomethingElse` is disposed before the `useSomething`.

  The reason for this change is for cases like:

  ```dart
  // Creates an AnimationController
  final animationController = useAnimationController();
  // Immediatly listen to the AnimationController
  useListenable(animationController);
  ```

  Before, when the widget was disposed, this caused an exception as
  `useListenable` unsubscribed to the `AnimationController` _after_ its `dispose`
  method was called.

**Non-breaking changes**:

- Added a way for hooks to potentially abort a widget rebuild.
- Added `StatefulHookWidget`, a `StatefulWidget` that can use hooks inside its `build` method.

## 0.9.0

- Added a `deactivate` life-cycle to `HookState`

## 0.8.0+1

- Fixed link to "Existing hooks" in `README.md`.

## 0.8.0:

Added `useFocusNode`

## 0.7.0:

- Added `useTextEditingController`, thanks to simolus3!

## 0.6.1:

- Added `useReassemble` hook, thanks to @SahandAkbarzadeh

## 0.6.0:

- Make hooks compatible with newer flutter stable version 1.7.8-hotfix.2.

## 0.4.0:

- Make hooks compatible with newer flutter version. (see https://groups.google.com/forum/#!topic/flutter-announce/hp1RNIgej38)

## 0.3.0:

- NEW: `usePrevious`, a hook that returns the previous argument is received.
- NEW: it is now impossible to call `inheritFromWidgetOfExactType` inside `initHook` of hooks. This forces authors to handle value updates.
- FIX: use List<Object> instead of List<dynamic> for keys. This fixes `implicit-dynamic` rule mistakenly reporting errors.
- NEW: Hooks are now visible on `HookElement` through `debugHooks` in development, for testing purposes.
- NEW: If a widget throws on the first build or after a hot-reload, next rebuilds can still add/edit hooks until one `build` finishes entirely.
- NEW: new life-cycle available on `HookState`: `didBuild`.
  This life-cycle is called synchronously right after `build` method of `HookWidget` finished.
- NEW: new `reassemble` life-cycle on `HookState`. It is equivalent to `State.ressemble` of statefulwidgets.
- NEW: `useStream` and `useFuture` now have an optional `preserveState` flag.
  This toggle how these hooks behave when changing the stream/future:
  If true (default) they keep the previous value, else they reset to initialState.

## 0.2.1:

- NEW: `useValueNotifier`, which creates a `ValueNotifier` similarly to `useState`. But without listening it.
  This can be useful to have a more granular rebuild when combined to `useValueListenable`.
- NEW: `useContext`, which exposes the `BuildContext` of the currently building `HookWidget`.

## 0.2.0:

- Made all existing hooks as static functions, and removed `HookContext`. The migration is as followed:

```dart
Widget build(HookContext context) {
    final state = context.useState(0);
}
```

becomes:

```dart
Widget build(BuildContext context) {
    final state = useState(0);
}
```

- Introduced keys for hooks and applied them to hooks where it makes sense.
- Added `useReducer` for complex state. It is similar to `useState` but is being managed by a `Reducer` and can only be changed by dispatching an action.
- fixes a bug where hot-reload without using hooks thrown an exception

## 0.1.0:

- `useMemoized` callback doesn't take the previous value anymore (to match React API)
  Use `useValueChanged` instead.
- Introduced `useEffect` and `useStreamController`
- fixed a bug where hot-reload while reordering/adding hooks did not work properly
- improved readme

## 0.0.1:

Added a few common hooks:

- `useStream`
- `useFuture`
- `useAnimationController`
- `useSingleTickerProvider`
- `useListenable`
- `useValueListenable`
- `useAnimation`

## 0.0.0:

- initial release
