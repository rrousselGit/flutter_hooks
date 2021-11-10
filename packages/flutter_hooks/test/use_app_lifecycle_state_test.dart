import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('sets the state', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    await tester.pumpWidget(
      HookBuilder(
        builder: (context) {
          final state = useAppLifecycleState();
          return Text('$state');
        },
      ),
    );

    expect(find.text('resumed'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(find.text('inactive'), findsOneWidget);
  });

  group('App lifecycle callbacks', () {
    var detachedCalled = false,
        resumedCalled = false,
        inactiveCalled = false,
        pausedCalled = false;
    AppLifecycleState? state;
    final widget = HookBuilder(builder: (context) {
      useAppLifecycleState(
        onResumed: () => resumedCalled = true,
        onDetached: () => detachedCalled = true,
        onInactive: () => inactiveCalled = true,
        onPaused: () => pausedCalled = true,
        onStateChanged: (newState) => state = newState,
      );
      return Container();
    });

    tearDown(() {
      resumedCalled = inactiveCalled = detachedCalled = pausedCalled = false;
      state = null;
    });

    testWidgets('Calls `onStateChanged` callback', (tester) async {
      await tester.pumpWidget(widget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(state, AppLifecycleState.resumed);
    });

    testWidgets('Calls `onResumed` callback', (tester) async {
      await tester.pumpWidget(widget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(resumedCalled, isTrue);
    });

    testWidgets('Calls `onDetached` callback', (tester) async {
      await tester.pumpWidget(widget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
      expect(detachedCalled, isTrue);
    });

    testWidgets('Calls `onPaused` callback', (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(widget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(pausedCalled, isTrue);
    });

    testWidgets('Calls `onInactive` callback', (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(widget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(inactiveCalled, isTrue);
    });
  });
}
