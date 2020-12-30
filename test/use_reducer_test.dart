import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        h.useReducer<int, int>((state, action) => 42);
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
        ' │ useReducer: 42\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  group('useReducer', () {
    testWidgets('basic', (tester) async {
      final reducer = MockReducer();

      Store<int, String> store;
      Future<void> pump() {
        return tester.pumpWidget(HookBuilder(
          builder: (context, h) {
            store = h.useReducer(reducer);
            return Container();
          },
        ));
      }

      when(reducer(null, null)).thenReturn(0);
      await pump();
      final element = tester.firstElement(find.byType(HookBuilder));

      verify(reducer(null, null)).called(1);
      verifyNoMoreInteractions(reducer);

      expect(store.state, 0);

      await pump();
      verifyNoMoreInteractions(reducer);
      expect(store.state, 0);

      when(reducer(0, 'foo')).thenReturn(1);

      store.dispatch('foo');

      verify(reducer(0, 'foo')).called(1);
      verifyNoMoreInteractions(reducer);
      expect(element.dirty, true);

      await pump();

      when(reducer(1, 'bar')).thenReturn(1);

      store.dispatch('bar');

      verify(reducer(1, 'bar')).called(1);
      verifyNoMoreInteractions(reducer);
      expect(element.dirty, false);
    });

    testWidgets('reducer required', (tester) async {
      await tester.pumpWidget(
        HookBuilder(
          builder: (context, h) {
            h.useReducer<void, void>(null);
            return Container();
          },
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('dispatch during build fails', (tester) async {
      final reducer = MockReducer();

      await tester.pumpWidget(
        HookBuilder(
          builder: (context, h) {
            h.useReducer(reducer.call).dispatch('Foo');
            return Container();
          },
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });
    testWidgets('first reducer call receive initialAction and initialState',
        (tester) async {
      final reducer = MockReducer();
      when(reducer(0, 'Foo')).thenReturn(42);

      await tester.pumpWidget(
        HookBuilder(
          builder: (context, h) {
            final result = h
                .useReducer(
                  reducer,
                  initialAction: 'Foo',
                  initialState: 0,
                )
                .state;
            return Text('$result', textDirection: TextDirection.ltr);
          },
        ),
      );

      expect(find.text('42'), findsOneWidget);
    });
    testWidgets('dispatchs reducer call must not return null', (tester) async {
      final reducer = MockReducer();

      Store<int, String> store;
      Future<void> pump() {
        return tester.pumpWidget(HookBuilder(
          builder: (context, h) {
            store = h.useReducer(reducer);
            return Container();
          },
        ));
      }

      when(reducer(null, null)).thenReturn(42);

      await pump();

      when(reducer(42, 'foo')).thenReturn(null);
      expect(() => store.dispatch('foo'), throwsAssertionError);

      await pump();
      expect(store.state, 42);
    });

    testWidgets('first reducer call must not return null', (tester) async {
      final reducer = MockReducer();

      await tester.pumpWidget(
        HookBuilder(
          builder: (context, h) {
            h.useReducer(reducer.call);
            return Container();
          },
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });
  });
}

class MockReducer extends Mock {
  int call(int state, String action);
}
