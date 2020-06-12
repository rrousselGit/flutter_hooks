import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

final effect = Func0<VoidCallback>();
final unrelated = Func0<void>();
List<Object> parameters;

Widget builder() => HookBuilder(builder: (context) {
      useEffect(effect.call, parameters);
      unrelated.call();
      return Container();
    });

void main() {
  tearDown(() {
    parameters = null;
    reset(unrelated);
    reset(effect);
  });
  testWidgets('useEffect null callback throws', (tester) async {
    await expectPump(
      () => tester.pumpWidget(HookBuilder(builder: (c) {
        useEffect(null);
        return Container();
      })),
      throwsAssertionError,
    );
  });
  testWidgets('useEffect calls callback on every build', (tester) async {
    final effect = Func0<VoidCallback>();
    final unrelated = Func0<void>();

    final dispose = Func0<void>();
    when(effect.call()).thenReturn(dispose.call);

    builder() => HookBuilder(builder: (context) {
          useEffect(effect.call);
          unrelated.call();
          return Container();
        });

    await tester.pumpWidget(builder());

    verifyInOrder([
      effect.call(),
      unrelated.call(),
    ]);
    verifyNoMoreInteractions(dispose);
    verifyNoMoreInteractions(effect);

    await tester.pumpWidget(builder());

    verifyInOrder([
      dispose.call(),
      effect.call(),
      unrelated.call(),
    ]);
    verifyNoMoreInteractions(dispose);
    verifyNoMoreInteractions(effect);
  });

  testWidgets(
      'useEffect with parameters calls callback when changing from null to something',
      (tester) async {
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect.call(),
      unrelated.call(),
    ]);
    verifyNoMoreInteractions(effect);

    parameters = ['foo'];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect.call(),
      unrelated.call(),
    ]);
    verifyNoMoreInteractions(effect);
  });

  testWidgets('useEffect adding parameters call callback', (tester) async {
    parameters = ['foo'];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect.call(),
      unrelated.call(),
    ]);
    verifyNoMoreInteractions(effect);

    parameters = ['foo', 42];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect.call(),
      unrelated.call(),
    ]);
    verifyNoMoreInteractions(effect);
  });

  testWidgets('useEffect removing parameters call callback', (tester) async {
    parameters = ['foo'];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect.call(),
      unrelated.call(),
    ]);
    verifyNoMoreInteractions(effect);

    parameters = [];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect.call(),
      unrelated.call(),
    ]);
    verifyNoMoreInteractions(effect);
  });
  testWidgets('useEffect changing parameters call callback', (tester) async {
    parameters = ['foo'];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect.call(),
      unrelated.call(),
    ]);
    verifyNoMoreInteractions(effect);

    parameters = ['bar'];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect.call(),
      unrelated.call(),
    ]);
    verifyNoMoreInteractions(effect);
  });
  testWidgets(
      'useEffect with same parameters but different arrays don t call callback',
      (tester) async {
    parameters = ['foo'];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect.call(),
      unrelated.call(),
    ]);
    verifyNoMoreInteractions(effect);

    parameters = ['foo'];
    await tester.pumpWidget(builder());

    verifyNoMoreInteractions(effect);
  });
  testWidgets(
      'useEffect with same array but different parameters don t call callback',
      (tester) async {
    parameters = ['foo'];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect.call(),
      unrelated.call(),
    ]);
    verifyNoMoreInteractions(effect);

    parameters.add('bar');
    await tester.pumpWidget(builder());

    verifyNoMoreInteractions(effect);
  });

  testWidgets('useEffect disposer called whenever callback called',
      (tester) async {
    final effect = Func0<VoidCallback>();
    List<Object> parameters;

    builder() => HookBuilder(builder: (context) {
          useEffect(effect.call, parameters);
          return Container();
        });

    parameters = ['foo'];
    final disposerA = Func0<void>();
    when(effect.call()).thenReturn(disposerA);

    await tester.pumpWidget(builder());

    verify(effect.call()).called(1);
    verifyNoMoreInteractions(effect);
    verifyZeroInteractions(disposerA);

    await tester.pumpWidget(builder());

    verifyNoMoreInteractions(effect);
    verifyZeroInteractions(disposerA);

    parameters = ['bar'];
    final disposerB = Func0<void>();
    when(effect.call()).thenReturn(disposerB);

    await tester.pumpWidget(builder());

    verifyInOrder([
      disposerA.call(),
      effect.call(),
    ]);
    verifyNoMoreInteractions(disposerA);
    verifyNoMoreInteractions(effect);
    verifyZeroInteractions(disposerB);

    await tester.pumpWidget(builder());

    verifyNoMoreInteractions(disposerA);
    verifyNoMoreInteractions(effect);
    verifyZeroInteractions(disposerB);

    await tester.pumpWidget(Container());

    verify(disposerB.call()).called(1);
    verifyNoMoreInteractions(disposerB);
    verifyNoMoreInteractions(disposerA);
    verifyNoMoreInteractions(effect);
  });
}
