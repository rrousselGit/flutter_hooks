import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  final builder = Func1<BuildContext, Widget>();
  final parameterBuilder = Func0<List>();
  final valueBuilder = Func0<int>();

  tearDown(() {
    reset(builder);
    reset(valueBuilder);
    reset(parameterBuilder);
  });

  testWidgets('invalid parameters', (tester) async {
    await tester.pumpWidget(HookBuilder(builder: (context) {
      useMemoized<dynamic>(null);
      return Container();
    }));
    expect(tester.takeException(), isAssertionError);

    await tester.pumpWidget(HookBuilder(builder: (context) {
      useMemoized<dynamic>(() {}, null);
      return Container();
    }));
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('memoized without parameter calls valueBuilder once',
      (tester) async {
    int result;

    when(valueBuilder.call()).thenReturn(42);

    when(builder.call(any)).thenAnswer((invocation) {
      result = useMemoized<int>(valueBuilder.call);
      return Container();
    });

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verify(valueBuilder.call()).called(1);
    verifyNoMoreInteractions(valueBuilder);
    expect(result, 42);

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyNoMoreInteractions(valueBuilder);
    expect(result, 42);

    await tester.pumpWidget(const SizedBox());

    verifyNoMoreInteractions(valueBuilder);
  });

  testWidgets(
      'memoized with parameter call valueBuilder again on parameter change',
      (tester) async {
    int result;

    when(valueBuilder.call()).thenReturn(0);
    when(parameterBuilder.call()).thenReturn(<dynamic>[]);

    when(builder.call(any)).thenAnswer((invocation) {
      result = useMemoized<int>(valueBuilder.call, parameterBuilder.call());
      return Container();
    });

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verify(valueBuilder.call()).called(1);
    verifyNoMoreInteractions(valueBuilder);
    expect(result, 0);

    /* No change */

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyNoMoreInteractions(valueBuilder);
    expect(result, 0);

    /* Add parameter */

    when(parameterBuilder.call()).thenReturn(<dynamic>['foo']);
    when(valueBuilder.call()).thenReturn(1);

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    expect(result, 1);
    verify(valueBuilder.call()).called(1);
    verifyNoMoreInteractions(valueBuilder);

    /* No change */

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyNoMoreInteractions(valueBuilder);
    expect(result, 1);

    /* Remove parameter */

    when(parameterBuilder.call()).thenReturn(<dynamic>[]);
    when(valueBuilder.call()).thenReturn(2);

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    expect(result, 2);
    verify(valueBuilder.call()).called(1);
    verifyNoMoreInteractions(valueBuilder);

    /* No change */

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyNoMoreInteractions(valueBuilder);
    expect(result, 2);

    /* DISPOSE */

    await tester.pumpWidget(const SizedBox());

    verifyNoMoreInteractions(valueBuilder);
  });

  testWidgets('memoized parameters compared in order', (tester) async {
    int result;

    when(builder.call(any)).thenAnswer((invocation) {
      result = useMemoized<int>(valueBuilder.call, parameterBuilder.call());
      return Container();
    });

    when(valueBuilder.call()).thenReturn(0);
    when(parameterBuilder.call()).thenReturn(<dynamic>['foo', 42, 24.0]);

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verify(valueBuilder.call()).called(1);
    verifyNoMoreInteractions(valueBuilder);
    expect(result, 0);

    /* Array reference changed but content didn't */

    when(parameterBuilder.call()).thenReturn(<dynamic>['foo', 42, 24.0]);
    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyNoMoreInteractions(valueBuilder);
    expect(result, 0);

    /* reoder */

    when(valueBuilder.call()).thenReturn(1);
    when(parameterBuilder.call()).thenReturn(<dynamic>[42, 'foo', 24.0]);

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verify(valueBuilder.call()).called(1);
    verifyNoMoreInteractions(valueBuilder);
    expect(result, 1);

    when(valueBuilder.call()).thenReturn(2);
    when(parameterBuilder.call()).thenReturn(<dynamic>[42, 24.0, 'foo']);

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verify(valueBuilder.call()).called(1);
    verifyNoMoreInteractions(valueBuilder);
    expect(result, 2);

    /* value change */

    when(valueBuilder.call()).thenReturn(3);
    when(parameterBuilder.call()).thenReturn(<dynamic>[43, 24.0, 'foo']);

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verify(valueBuilder.call()).called(1);
    verifyNoMoreInteractions(valueBuilder);
    expect(result, 3);

    /* Comparison is done using operator== */

    // type change
    when(parameterBuilder.call()).thenReturn(<dynamic>[43.0, 24.0, 'foo']);

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyNoMoreInteractions(valueBuilder);
    expect(result, 3);

    /* DISPOSE */

    await tester.pumpWidget(const SizedBox());

    verifyNoMoreInteractions(valueBuilder);
  });

  testWidgets(
      'memoized parameter reference do not change don\'t call valueBuilder',
      (tester) async {
    int result;
    final parameters = <dynamic>[];

    when(builder.call(any)).thenAnswer((invocation) {
      result = useMemoized<int>(valueBuilder.call, parameterBuilder.call());
      return Container();
    });

    when(valueBuilder.call()).thenReturn(0);
    when(parameterBuilder.call()).thenReturn(parameters);

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verify(valueBuilder.call()).called(1);
    verifyNoMoreInteractions(valueBuilder);
    expect(result, 0);

    /* Array content but reference didn't */
    parameters.add(42);

    await tester.pumpWidget(HookBuilder(builder: builder.call));

    verifyNoMoreInteractions(valueBuilder);

    /* DISPOSE */

    await tester.pumpWidget(const SizedBox());

    verifyNoMoreInteractions(valueBuilder);
  });
}
