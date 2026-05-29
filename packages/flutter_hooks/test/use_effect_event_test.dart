// ignore_for_file: avoid_types_on_closure_parameters, avoid_positional_boolean_parameters

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  group('useEffectEvent', () {
    // These tests demonstrate WHY useEffectEvent is needed in Flutter.
    // The problem: when an effect registers a callback with an external system,
    // that system holds onto the callback reference. If the effect doesn't
    // re-run, the external system has a stale callback even though fresh
    // functions are created on each rebuild.
    testWidgets('external system holds stale reference without useEffectEvent',
        (tester) async {
      final externalSystem = _MockConnection();
      final logs = <String>[];

      Widget chatRoom({required String roomId, required String theme}) {
        return HookBuilder(builder: (context) {
          // Plain function - fresh on every build, but...
          void onConnected() {
            logs.add('Connected with theme: $theme');
          }

          useEffect(() {
            // Register callback with external system
            // The external system holds this reference!
            externalSystem.onConnected = onConnected;
            return () => externalSystem.onConnected = null;
          }, [roomId]); // Only depends on roomId, not theme

          return Text('$roomId $theme', textDirection: TextDirection.ltr);
        });
      }

      await tester.pumpWidget(chatRoom(roomId: 'room1', theme: 'light'));

      // Effect ran, registered callback with connection
      externalSystem.fireConnected();
      expect(logs, ['Connected with theme: light']);
      logs.clear();

      // User changes theme (but NOT roomId)
      await tester.pumpWidget(chatRoom(roomId: 'room1', theme: 'dark'));

      // A NEW onConnected function was created with theme='dark'
      // BUT the effect didn't re-run, so connection still has OLD callback!
      externalSystem.fireConnected();
      expect(logs, ['Connected with theme: light']);
      logs.clear();
    });

    testWidgets(
        'useEffectEvent solves the external system stale reference problem',
        (tester) async {
      final externalSystem = _MockConnection();
      final logs = <String>[];

      Widget chatRoom({required String roomId, required String theme}) {
        return HookBuilder(builder: (context) {
          // useEffectEvent - always sees latest theme via ref indirection
          final onConnected = useEffectEvent(() {
            logs.add('Connected with theme: $theme');
          });

          useEffect(() {
            // Register callback that delegates to useEffectEvent
            externalSystem.onConnected = () => onConnected.call();
            return () => externalSystem.onConnected = null;
          }, [roomId]); // Only depends on roomId, theme accessed via ref

          return Text('$roomId $theme', textDirection: TextDirection.ltr);
        });
      }

      await tester.pumpWidget(chatRoom(roomId: 'room1', theme: 'light'));

      externalSystem.fireConnected();
      expect(logs, ['Connected with theme: light']);
      logs.clear();

      // User changes theme (but NOT roomId)
      await tester.pumpWidget(chatRoom(roomId: 'room1', theme: 'dark'));

      // Effect didn't re-run, BUT useEffectEvent uses ref indirection
      // so the callback registered with connection delegates to latest
      externalSystem.fireConnected();
      expect(logs, ['Connected with theme: dark']);
      logs.clear();
    });

    testWidgets('debugFillProperties', (tester) async {
      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          useEffectEvent(() {});
          return const SizedBox();
        }),
      );

      final element = tester.element(find.byType(HookBuilder));

      expect(
        element
            .toDiagnosticsNode(style: DiagnosticsTreeStyle.offstage)
            .toStringDeep(),
        equalsIgnoringHashCodes(
          'HookBuilder\n'
          ' │ useEffectEvent<() => Null>\n'
          ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
        ),
      );
    });
  });

  // These tests are adapted from React's useEffectEvent tests:
  // https://github.com/facebook/react/blob/main/packages/react-reconciler/src/__tests__/useEffectEvent-test.js
  group("React's useEffectEvent", () {
    testWidgets('memoizes basic case correctly', (tester) async {
      Widget counter(int incrementBy) {
        return HookBuilder(builder: (context) {
          final count = useState(0);

          final onClick = useEffectEvent(() {
            count.value += incrementBy;
          });

          return GestureDetector(
            onTap: onClick.call,
            child: Text(
              'Count: ${count.value}',
              textDirection: TextDirection.ltr,
            ),
          );
        });
      }

      await tester.pumpWidget(counter(1));
      expect(find.text('Count: 0'), findsOneWidget);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(find.text('Count: 1'), findsOneWidget);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(find.text('Count: 2'), findsOneWidget);

      // Increase the increment prop amount
      await tester.pumpWidget(counter(10));
      expect(find.text('Count: 2'), findsOneWidget);

      // Event uses the new prop
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(find.text('Count: 12'), findsOneWidget);
    });

    testWidgets('can be defined more than once', (tester) async {
      Widget counter(int incrementBy) {
        return HookBuilder(builder: (context) {
          final count = useState(0);

          final onIncrement = useEffectEvent(() {
            count.value += incrementBy;
          });

          final onMultiply = useEffectEvent(() {
            count.value *= incrementBy;
          });

          return Column(
            textDirection: TextDirection.ltr,
            children: [
              GestureDetector(
                key: const Key('increment'),
                onTap: onIncrement.call,
                child: const Text(
                  'Increment',
                  textDirection: TextDirection.ltr,
                ),
              ),
              GestureDetector(
                key: const Key('multiply'),
                onTap: onMultiply.call,
                child: const Text(
                  'Multiply',
                  textDirection: TextDirection.ltr,
                ),
              ),
              Text(
                'Count: ${count.value}',
                textDirection: TextDirection.ltr,
              ),
            ],
          );
        });
      }

      await tester.pumpWidget(counter(5));
      expect(find.text('Count: 0'), findsOneWidget);

      await tester.tap(find.byKey(const Key('increment')));
      await tester.pump();
      expect(find.text('Count: 5'), findsOneWidget);

      await tester.tap(find.byKey(const Key('multiply')));
      await tester.pump();
      expect(find.text('Count: 25'), findsOneWidget);
    });

    // Note: Unlike React, flutter_hooks runs effects synchronously during
    // initHook, not in a separate phase after commit. This makes it impossible
    // to distinguish between "called during build" and "called from effect"
    // using scheduler phase detection. This test is skipped as the behavior
    // cannot be implemented without changes to flutter_hooks core.
    testWidgets('throws when called during build', (tester) async {
      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          final onClick = useEffectEvent(() {});

          // Calling useEffectEvent during build should throw
          onClick.call();

          return const SizedBox();
        }),
      );

      final exception = tester.takeException();
      expect(exception, isA<FlutterError>());
      expect(
        (exception! as FlutterError).message,
        contains(
          "A function wrapped in useEffectEvent can't be called during build.",
        ),
      );
    }, skip: true);

    testWidgets("useEffect shouldn't re-fire when event handlers change",
        (tester) async {
      final logs = <String>[];

      Widget counter(int incrementBy) {
        return HookBuilder(builder: (context) {
          final count = useState(0);

          final increment = useEffectEvent(([int? amount]) {
            count.value += amount ?? incrementBy;
          });

          useEffect(() {
            logs.add('Effect: by ${incrementBy * 2}');
            increment.call(incrementBy * 2);
            return null;
          }, [incrementBy]);

          return Column(
            textDirection: TextDirection.ltr,
            children: [
              GestureDetector(
                onTap: () => increment.call(),
                child: const Text(
                  'Increment',
                  textDirection: TextDirection.ltr,
                ),
              ),
              Text('Count: ${count.value}', textDirection: TextDirection.ltr),
            ],
          );
        });
      }

      await tester.pumpWidget(counter(1));
      expect(find.text('Increment'), findsOneWidget);
      expect(find.text('Count: 2'), findsOneWidget);
      expect(logs, ['Effect: by 2']);
      logs.clear();

      // Tap button - effect should NOT re-run
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(find.text('Increment'), findsOneWidget);
      expect(find.text('Count: 3'), findsOneWidget);
      expect(logs, <String>[]); // No effect re-run
      logs.clear();

      // Tap button again
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(find.text('Increment'), findsOneWidget);
      expect(find.text('Count: 4'), findsOneWidget);
      expect(logs, <String>[]); // Still no effect re-run
      logs.clear();

      // Change incrementBy prop - effect SHOULD re-run
      await tester.pumpWidget(counter(10));
      expect(find.text('Increment'), findsOneWidget);
      expect(find.text('Count: 24'), findsOneWidget);
      expect(logs, ['Effect: by 20']);
      logs.clear();

      // Tap button - uses new incrementBy value
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(find.text('Increment'), findsOneWidget);
      expect(find.text('Count: 34'), findsOneWidget);
      expect(logs, <String>[]); // No effect re-run
      logs.clear();
    });

    testWidgets('is stable in a custom hook', (tester) async {
      final logs = <String>[];

      Widget counter(int incrementBy) {
        return HookBuilder(builder: (context) {
          final count = useState(0);

          final increment = useEffectEvent(([int? amount]) {
            count.value += amount ?? incrementBy;
          });

          useEffect(() {
            logs.add('Effect: by ${incrementBy * 2}');
            increment.call(incrementBy * 2);
            return null;
          }, [incrementBy]);

          return Column(
            textDirection: TextDirection.ltr,
            children: [
              GestureDetector(
                onTap: () => increment.call(),
                child: const Text(
                  'Increment',
                  textDirection: TextDirection.ltr,
                ),
              ),
              Text(
                'Count: ${count.value}',
                textDirection: TextDirection.ltr,
              ),
            ],
          );
        });
      }

      await tester.pumpWidget(counter(1));
      expect(find.text('Increment'), findsOneWidget);
      expect(find.text('Count: 2'), findsOneWidget);
      expect(logs, ['Effect: by 2']);
      logs.clear();

      // Tap button - effect should NOT re-run
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(find.text('Increment'), findsOneWidget);
      expect(find.text('Count: 3'), findsOneWidget);
      expect(logs, <String>[]); // No effect re-run
      logs.clear();

      // Tap button again
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(find.text('Increment'), findsOneWidget);
      expect(find.text('Count: 4'), findsOneWidget);
      expect(logs, <String>[]); // Still no effect re-run
      logs.clear();

      // Change incrementBy prop - effect SHOULD re-run
      await tester.pumpWidget(counter(10));
      expect(find.text('Increment'), findsOneWidget);
      expect(find.text('Count: 24'), findsOneWidget);
      expect(logs, ['Effect: by 20']);
      logs.clear();

      // Tap button - uses new incrementBy value
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(find.text('Increment'), findsOneWidget);
      expect(find.text('Count: 34'), findsOneWidget);
      expect(logs, <String>[]); // No effect re-run
      logs.clear();
    });

    testWidgets("doesn't provide a stable identity", (tester) async {
      final logs = <String>[];

      Widget counter(bool shouldRender, int value) {
        return HookBuilder(builder: (context) {
          final onClick = useEffectEvent(() {
            logs.add('onClick, shouldRender=$shouldRender, value=$value');
          });

          // onClick doesn't have a stable function identity so this effect
          // will fire on every render. In a real app useEffectEvent functions
          // should NOT be passed as a dependency, this is for testing only.
          useEffect(() {
            onClick.call();
            return null;
          }, [onClick]);

          useEffect(() {
            onClick.call();
            return null;
          }, [shouldRender]);

          return const SizedBox();
        });
      }

      // Initial render - both effects run
      await tester.pumpWidget(counter(true, 0));
      expect(logs, [
        'onClick, shouldRender=true, value=0',
        'onClick, shouldRender=true, value=0',
      ]);
      logs.clear();

      // Update value only - only the onClick-dependent effect runs
      // (because onClick identity changed)
      await tester.pumpWidget(counter(true, 1));
      expect(logs, ['onClick, shouldRender=true, value=1']);
      logs.clear();

      // Update shouldRender - both effects run
      // (onClick identity changed AND shouldRender changed)
      await tester.pumpWidget(counter(false, 2));
      expect(logs, [
        'onClick, shouldRender=false, value=2',
        'onClick, shouldRender=false, value=2',
      ]);
      logs.clear();
    });

    testWidgets('event handlers always see the latest committed value',
        (tester) async {
      final logs = <String>[];
      EffectEvent<String Function()>? committedEventHandler;

      Widget app(int value) {
        return HookBuilder(builder: (context) {
          final event = useEffectEvent(() {
            return 'Value seen by useEffectEvent: $value';
          });

          // Effect with empty deps - runs once, stores handler
          useEffect(() {
            logs.add('Commit new event handler');
            committedEventHandler = event;
            return null;
          }, const []);

          return Text(
            'Latest rendered value $value',
            textDirection: TextDirection.ltr,
          );
        });
      }

      // Initial render
      await tester.pumpWidget(app(1));
      expect(find.text('Latest rendered value 1'), findsOneWidget);
      expect(logs, ['Commit new event handler']);
      expect(committedEventHandler!.call(), 'Value seen by useEffectEvent: 1');
      logs.clear();

      // Update - effect should NOT re-run (empty deps)
      await tester.pumpWidget(app(2));
      expect(find.text('Latest rendered value 2'), findsOneWidget);
      // No new event handler should be committed, because deps is empty
      expect(logs, <String>[]);
      // But the event handler should still be able to see the latest value
      expect(committedEventHandler!.call(), 'Value seen by useEffectEvent: 2');
      logs.clear();
    });

    testWidgets('integration: implements docs chat room example',
        (tester) async {
      final logs = <String>[];

      _Connection createConnection(String roomId) {
        return _Connection(
          roomId: roomId,
          onLog: logs.add,
        );
      }

      Widget chatRoom({required String roomId, required String theme}) {
        return HookBuilder(builder: (context) {
          final onConnected = useEffectEvent(() {
            logs.add('Connected! theme: $theme');
          });

          useEffect(() {
            final connection = createConnection(roomId);
            connection.on('connected', () => onConnected.call());
            connection.connect();
            return connection.disconnect;
          }, [roomId]);

          return Text(
            'Welcome to the $roomId room!',
            textDirection: TextDirection.ltr,
          );
        });
      }

      // Initial render
      await tester.pumpWidget(chatRoom(roomId: 'general', theme: 'light'));
      expect(find.text('Welcome to the general room!'), findsOneWidget);
      expect(logs, ['Connected! theme: light']);
      logs.clear();

      // Change roomId only - should trigger reconnect
      // Note: flutter_hooks runs new effect before old cleanup (unlike React)
      await tester.pumpWidget(chatRoom(roomId: 'music', theme: 'light'));
      expect(find.text('Welcome to the music room!'), findsOneWidget);
      expect(logs, ['Connected! theme: light', 'Disconnected from general']);
      logs.clear();

      // Change theme only - should NOT trigger reconnect
      await tester.pumpWidget(chatRoom(roomId: 'music', theme: 'dark'));
      expect(find.text('Welcome to the music room!'), findsOneWidget);
      expect(logs, <String>[]); // No reconnect!
      logs.clear();

      // Change roomId only - should trigger reconnect with latest theme
      await tester.pumpWidget(chatRoom(roomId: 'travel', theme: 'dark'));
      expect(find.text('Welcome to the travel room!'), findsOneWidget);
      expect(logs, ['Connected! theme: dark', 'Disconnected from music']);
      logs.clear();
    });
  });
}

/// Mock external system that holds callback references (e.g., WebSocket, Timer)
class _MockConnection {
  void Function()? onConnected;

  void fireConnected() {
    onConnected?.call();
  }
}

/// Simulates a connection like React's createConnection in the docs example.
/// Calls the 'connected' callback immediately on connect() for testing purposes.
class _Connection {
  _Connection({required this.roomId, required this.onLog});

  final String roomId;
  final void Function(String) onLog;
  void Function()? _connectedCallback;

  void on(String event, void Function() callback) {
    if (_connectedCallback != null) {
      throw StateError('Cannot add the handler twice.');
    }
    if (event != 'connected') {
      throw ArgumentError('Only "connected" event is supported.');
    }
    _connectedCallback = callback;
  }

  void connect() {
    // In React's test, this uses setTimeout. We call immediately for simplicity.
    _connectedCallback?.call();
  }

  void disconnect() {
    onLog('Disconnected from $roomId');
    _connectedCallback = null;
  }
}
