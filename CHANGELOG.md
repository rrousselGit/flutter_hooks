## 0.1.0:

- `useMemoized` callback doesn't take the previous value anymore (to match React API)
Use `useValueChanged` instead.
- Introduced `useEffect` and `useStreamController`
- fixed a bug where hot-reload while reordering/adding hooks did not work properly

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
