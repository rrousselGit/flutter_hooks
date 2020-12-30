import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  final valueBuilder = MockValueBuilder();

  tearDown(() {
    reset(valueBuilder);
  });

  testWidgets('invalid parameters', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        h.useMemoized<void>(null);
        return Container();
      }),
    );

    expect(tester.takeException(), isAssertionError);

    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        h.useMemoized(() {}, null);
        return Container();
      }),
    );
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('memoized without parameter calls valueBuilder once',
      (tester) async {
    int result;

    when(valueBuilder()).thenReturn(42);

    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        result = h.useMemoized<int>(valueBuilder);
        return Container();
      }),
    );

    verify(valueBuilder()).called(1);
    verifyNoMoreInteractions(valueBuilder);
    expect(result, 42);

    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        result = h.useMemoized<int>(valueBuilder);
        return Container();
      }),
    );

    verifyNoMoreInteractions(valueBuilder);
    expect(result, 42);

    await tester.pumpWidget(const SizedBox());

    verifyNoMoreInteractions(valueBuilder);
  });

  testWidgets(
      'memoized with parameter call valueBuilder again on parameter change',
      (tester) async {
    int result;

    when(valueBuilder()).thenReturn(0);

    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        result = h.useMemoized<int>(valueBuilder, []);
        return Container();
      }),
    );

    verify(valueBuilder()).called(1);
    verifyNoMoreInteractions(valueBuilder);
    expect(result, 0);

    /* No change */

    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        result = h.useMemoized<int>(valueBuilder, []);
        return Container();
      }),
    );

    verifyNoMoreInteractions(valueBuilder);
    expect(result, 0);

    /* Add parameter */

    when(valueBuilder()).thenReturn(1);

    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        result = h.useMemoized<int>(valueBuilder, ['foo']);
        return Container();
      }),
    );

    expect(result, 1);
    verify(valueBuilder()).called(1);
    verifyNoMoreInteractions(valueBuilder);

    /* No change */

    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        result = h.useMemoized<int>(valueBuilder, ['foo']);
        return Container();
      }),
    );

    verifyNoMoreInteractions(valueBuilder);
    expect(result, 1);

    /* Remove parameter */

    when(valueBuilder()).thenReturn(2);

    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        result = h.useMemoized<int>(valueBuilder, []);
        return Container();
      }),
    );

    expect(result, 2);
    verify(valueBuilder()).called(1);
    verifyNoMoreInteractions(valueBuilder);

    /* No change */

    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        result = h.useMemoized<int>(valueBuilder, []);
        return Container();
      }),
    );

    verifyNoMoreInteractions(valueBuilder);
    expect(result, 2);

    /* DISPOSE */

    await tester.pumpWidget(const SizedBox());

    verifyNoMoreInteractions(valueBuilder);
  });

  testWidgets('memoized parameters compared in order', (tester) async {
    int result;

    when(valueBuilder()).thenReturn(0);

    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        result = h.useMemoized<int>(valueBuilder, ['foo', 42, 24.0]);
        return Container();
      }),
    );

    verify(valueBuilder()).called(1);
    verifyNoMoreInteractions(valueBuilder);
    expect(result, 0);

    /* Array reference changed but content didn't */

    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        result = h.useMemoized<int>(valueBuilder, ['foo', 42, 24.0]);
        return Container();
      }),
    );

    verifyNoMoreInteractions(valueBuilder);
    expect(result, 0);

    /* reoder */

    when(valueBuilder()).thenReturn(1);

    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        result = h.useMemoized<int>(valueBuilder, [42, 'foo', 24.0]);
        return Container();
      }),
    );

    verify(valueBuilder()).called(1);
    verifyNoMoreInteractions(valueBuilder);
    expect(result, 1);

    when(valueBuilder()).thenReturn(2);

    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        result = h.useMemoized<int>(valueBuilder, [42, 24.0, 'foo']);
        return Container();
      }),
    );

    verify(valueBuilder()).called(1);
    verifyNoMoreInteractions(valueBuilder);
    expect(result, 2);

    /* value change */

    when(valueBuilder()).thenReturn(3);

    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        result = h.useMemoized<int>(valueBuilder, [43, 24.0, 'foo']);
        return Container();
      }),
    );

    verify(valueBuilder()).called(1);
    verifyNoMoreInteractions(valueBuilder);
    expect(result, 3);

    /* Comparison is done using operator== */

    // type change
    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        result = h.useMemoized<int>(valueBuilder, [43, 24.0, 'foo']);
        return Container();
      }),
    );

    verifyNoMoreInteractions(valueBuilder);
    expect(result, 3);

    /* DISPOSE */

    await tester.pumpWidget(const SizedBox());

    verifyNoMoreInteractions(valueBuilder);
  });

  testWidgets(
      "memoized parameter reference do not change don't call valueBuilder",
      (tester) async {
    int result;
    final parameters = <Object>[];

    when(valueBuilder()).thenReturn(0);

    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        result = h.useMemoized<int>(valueBuilder, parameters);
        return Container();
      }),
    );

    verify(valueBuilder()).called(1);
    verifyNoMoreInteractions(valueBuilder);
    expect(result, 0);

    /* Array content but reference didn't */
    parameters.add(42);

    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        result = h.useMemoized<int>(valueBuilder, parameters);
        return Container();
      }),
    );

    verifyNoMoreInteractions(valueBuilder);

    /* DISPOSE */

    await tester.pumpWidget(const SizedBox());

    verifyNoMoreInteractions(valueBuilder);
  });

  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context, h) {
        h.useMemoized<Future<int>>(() => Future.value(10));
        h.useMemoized<int>(() => 43);
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
        " │ useMemoized<Future<int>>: Instance of 'Future<int>'\n"
        ' │ useMemoized<int>: 43\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });
}

class MockValueBuilder extends Mock {
  int call();
}
