import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('useValueChanged basic', (tester) async {
    var value = 42;
    final useValueChanged = Func2<int, String, String>();
    String result;

    pump() => tester.pumpWidget(HookBuilder(
          builder: (context) {
            result = context.useValueChanged(value, useValueChanged.call);
            return Container();
          },
        ));
    await pump();

    final HookElement context = find.byType(HookBuilder).evaluate().first;

    expect(result, null);
    verifyNoMoreInteractions(useValueChanged);
    expect(context.dirty, false);

    await pump();

    expect(result, null);
    verifyNoMoreInteractions(useValueChanged);
    expect(context.dirty, false);

    value++;
    when(useValueChanged.call(any, any)).thenReturn('Hello');
    await pump();

    verify(useValueChanged.call(42, null));
    expect(result, 'Hello');
    verifyNoMoreInteractions(useValueChanged);
    expect(context.dirty, false);

    await pump();

    expect(result, 'Hello');
    verifyNoMoreInteractions(useValueChanged);
    expect(context.dirty, false);

    value++;
    when(useValueChanged.call(any, any)).thenReturn('Foo');
    await pump();

    expect(result, 'Foo');
    verify(useValueChanged.call(43, 'Hello'));
    verifyNoMoreInteractions(useValueChanged);
    expect(context.dirty, false);

    await pump();

    expect(result, 'Foo');
    verifyNoMoreInteractions(useValueChanged);
    expect(context.dirty, false);

    // dispose
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('valueChanged required', (tester) async {
    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        context.useValueChanged<int, int>(42, null);
        return Container();
      },
    ));

    expect(tester.takeException(), isAssertionError);
  });
}
