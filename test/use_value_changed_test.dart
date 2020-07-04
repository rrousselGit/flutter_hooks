import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('useValueChanged basic', (tester) async {
    var value = 42;
    final _useValueChanged = MockValueChanged();
    String result;

    Future<void> pump() {
      return tester.pumpWidget(
        HookBuilder(builder: (context) {
          result = useValueChanged(value, _useValueChanged);
          return Container();
        }),
      );
    }

    await pump();

    final context = find.byType(HookBuilder).evaluate().first;

    expect(result, null);
    verifyNoMoreInteractions(_useValueChanged);
    expect(context.dirty, false);

    await pump();

    expect(result, null);
    verifyNoMoreInteractions(_useValueChanged);
    expect(context.dirty, false);

    value++;
    when(_useValueChanged(any, any)).thenReturn('Hello');
    await pump();

    verify(_useValueChanged(42, null));
    expect(result, 'Hello');
    verifyNoMoreInteractions(_useValueChanged);
    expect(context.dirty, false);

    await pump();

    expect(result, 'Hello');
    verifyNoMoreInteractions(_useValueChanged);
    expect(context.dirty, false);

    value++;
    when(_useValueChanged(any, any)).thenReturn('Foo');
    await pump();

    expect(result, 'Foo');
    verify(_useValueChanged(43, 'Hello'));
    verifyNoMoreInteractions(_useValueChanged);
    expect(context.dirty, false);

    await pump();

    expect(result, 'Foo');
    verifyNoMoreInteractions(_useValueChanged);
    expect(context.dirty, false);

    // dispose
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('valueChanged required', (tester) async {
    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        useValueChanged<int, int>(42, null);
        return Container();
      },
    ));

    expect(tester.takeException(), isAssertionError);
  });
}

class MockValueChanged extends Mock {
  String call(int value, String previous);
}
