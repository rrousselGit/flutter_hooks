import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  group('useValueNotifier', () {
    testWidgets('useValueNotifier basic', (tester) async {
      ValueNotifier<int> state;
      HookElement element;
      final listener = Func0<void>();

      await tester.pumpWidget(HookBuilder(
        builder: (context) {
          element = context as HookElement;
          state = useValueNotifier(42);
          return Container();
        },
      ));

      state.addListener(listener.call);

      expect(state.value, 42);
      expect(element.dirty, false);
      verifyNoMoreInteractions(listener);

      await tester.pump();

      verifyNoMoreInteractions(listener);
      expect(state.value, 42);
      expect(element.dirty, false);

      state.value++;
      verify(listener.call()).called(1);
      verifyNoMoreInteractions(listener);
      expect(element.dirty, false);
      await tester.pump();

      expect(state.value, 43);
      expect(element.dirty, false);
      verifyNoMoreInteractions(listener);

      // dispose
      await tester.pumpWidget(const SizedBox());

      // ignore: invalid_use_of_protected_member
      expect(() => state.hasListeners, throwsFlutterError);
    });

    testWidgets('no initial data', (tester) async {
      ValueNotifier<int> state;
      HookElement element;
      final listener = Func0<void>();

      await tester.pumpWidget(HookBuilder(
        builder: (context) {
          element = context as HookElement;
          state = useValueNotifier();
          return Container();
        },
      ));

      state.addListener(listener.call);

      expect(state.value, null);
      expect(element.dirty, false);
      verifyNoMoreInteractions(listener);

      await tester.pump();

      expect(state.value, null);
      expect(element.dirty, false);
      verifyNoMoreInteractions(listener);

      state.value = 43;
      expect(element.dirty, false);
      verify(listener.call()).called(1);
      verifyNoMoreInteractions(listener);
      await tester.pump();

      expect(state.value, 43);
      expect(element.dirty, false);
      verifyNoMoreInteractions(listener);

      // dispose
      await tester.pumpWidget(const SizedBox());

      // ignore: invalid_use_of_protected_member
      expect(() => state.hasListeners, throwsFlutterError);
    });

    testWidgets('creates new valuenotifier when key change', (tester) async {
      ValueNotifier<int> state;
      ValueNotifier<int> previous;

      await tester.pumpWidget(HookBuilder(
        builder: (context) {
          state = useValueNotifier(42);
          return Container();
        },
      ));

      await tester.pumpWidget(HookBuilder(
        builder: (context) {
          previous = state;
          state = useValueNotifier(42, <dynamic>[42]);
          return Container();
        },
      ));

      expect(state, isNot(previous));
    });
    testWidgets('instance stays the same when key don\' change',
        (tester) async {
      ValueNotifier<int> state;
      ValueNotifier<int> previous;

      await tester.pumpWidget(HookBuilder(
        builder: (context) {
          state = useValueNotifier(null, <dynamic>[42]);
          return Container();
        },
      ));

      await tester.pumpWidget(HookBuilder(
        builder: (context) {
          previous = state;
          state = useValueNotifier(42, <dynamic>[42]);
          return Container();
        },
      ));

      expect(state, previous);
    });
  });
}
