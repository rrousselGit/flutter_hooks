import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('sets the state', (tester) async {
    AppLifecycleState? state;
    var called = true;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(HookBuilder(builder: (context) {
      state = useAppLifecycleState();
      called = true;
      return Container();
    }));

    expect(state, AppLifecycleState.resumed);
    expect(called, isTrue);
    called = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(called, isTrue);
    expect(state, AppLifecycleState.inactive);
  });
  group('App lifecycle callbacks', () {
    var detachedCalled = false,
        resumedCalled = false,
        inactiveCalled = false,
        pausedCalled = false;
    AppLifecycleState? state;
    final widget = HookBuilder(builder: (context) {
      useAppLifecycleState(
        onResumed: (_) => resumedCalled = true,
        onDetached: (_) => detachedCalled = true,
        onInactive: (_) => inactiveCalled = true,
        onPaused: (_) => pausedCalled = true,
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
