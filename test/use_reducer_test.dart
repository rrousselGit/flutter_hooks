import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  group('useReducer', () {
    testWidgets('basic', (tester) async {
      final reducer = Func2<int, String, int>();

      Store<int, String> store;
      pump() => tester.pumpWidget(HookBuilder(
            builder: (context) {
              store = useReducer(reducer.call);
              return Container();
            },
          ));

      when(reducer.call(null, null)).thenReturn(0);
      await pump();
      final element = tester.firstElement(find.byType(HookBuilder));

      verify(reducer.call(null, null)).called(1);
      verifyNoMoreInteractions(reducer);

      expect(store.state, 0);

      await pump();
      verifyNoMoreInteractions(reducer);
      expect(store.state, 0);

      when(reducer.call(0, 'foo')).thenReturn(1);

      store.dispatch('foo');

      verify(reducer.call(0, 'foo')).called(1);
      verifyNoMoreInteractions(reducer);
      expect(element.dirty, true);

      await pump();

      when(reducer.call(1, 'bar')).thenReturn(1);

      store.dispatch('bar');

      verify(reducer.call(1, 'bar')).called(1);
      verifyNoMoreInteractions(reducer);
      expect(element.dirty, false);
    });

    testWidgets('reducer required', (tester) async {
      await expectPump(
        () => tester.pumpWidget(HookBuilder(
              builder: (context) {
                useReducer<void, void>(null);
                return Container();
              },
            )),
        throwsAssertionError,
      );
    });

    testWidgets('dispatch during build fails', (tester) async {
      final reducer = Func2<int, String, int>();

      await expectPump(
        () => tester.pumpWidget(HookBuilder(
              builder: (context) {
                useReducer(reducer.call).dispatch('Foo');
                return Container();
              },
            )),
        throwsAssertionError,
      );
    });
    testWidgets('first reducer call receive initialAction and initialState',
        (tester) async {
      final reducer = Func2<int, String, int>();

      when(reducer.call(0, 'Foo')).thenReturn(0);
      await expectPump(
        () => tester.pumpWidget(HookBuilder(
              builder: (context) {
                useReducer(
                  reducer.call,
                  initialAction: 'Foo',
                  initialState: 0,
                );
                return Container();
              },
            )),
        completes,
      );
    });
    testWidgets('dispatchs reducer call must not return null', (tester) async {
      final reducer = Func2<int, String, int>();

      Store<int, String> store;
      pump() => tester.pumpWidget(HookBuilder(
            builder: (context) {
              store = useReducer(reducer.call);
              return Container();
            },
          ));

      when(reducer.call(null, null)).thenReturn(42);

      await pump();

      when(reducer.call(42, 'foo')).thenReturn(null);
      expect(() => store.dispatch('foo'), throwsAssertionError);

      await pump();
      expect(store.state, 42);
    });

    testWidgets('first reducer call must not return null', (tester) async {
      final reducer = Func2<int, String, int>();

      await expectPump(
        () => tester.pumpWidget(HookBuilder(
              builder: (context) {
                useReducer(reducer.call);
                return Container();
              },
            )),
        throwsAssertionError,
      );
    });
  });
}
