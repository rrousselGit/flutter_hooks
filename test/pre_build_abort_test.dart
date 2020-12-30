import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock.dart';

void main() {
  testWidgets(
      'setState during build still cause mayHaveChange to rebuild the element',
      (tester) async {
    final number = ValueNotifier(0);

    await tester.pumpWidget(
      HookBuilder(builder: (c, h) {
        final state = h.useState(false);
        state.value = true;
        final isPositive = h.use(IsPositiveHook(number));
        return Text('$isPositive', textDirection: TextDirection.ltr);
      }),
    );

    expect(find.text('true'), findsOneWidget);
    expect(find.text('false'), findsNothing);

    number.value = -1;
    await tester.pump();

    expect(find.text('false'), findsOneWidget);
    expect(find.text('true'), findsNothing);
  });

  testWidgets('setState during build still allow mayHaveChange to abort builds',
      (tester) async {
    final number = ValueNotifier(0);

    var buildCount = 0;

    await tester.pumpWidget(
      HookBuilder(builder: (c, h) {
        buildCount++;
        final state = h.useState(false);
        state.value = true;
        final isPositive = h.use(IsPositiveHook(number));
        return Text('$isPositive', textDirection: TextDirection.ltr);
      }),
    );

    expect(find.text('true'), findsOneWidget);
    expect(find.text('false'), findsNothing);
    expect(buildCount, 1);

    number.value = 10;
    await tester.pump();

    expect(find.text('true'), findsOneWidget);
    expect(find.text('false'), findsNothing);
    expect(buildCount, 1);
  });

  testWidgets('shouldRebuild defaults to true', (tester) async {
    MayRebuildState first;
    var buildCount = 0;

    await tester.pumpWidget(
      HookBuilder(builder: (c, h) {
        buildCount++;
        first = h.use(const MayRebuild());

        return Container();
      }),
    );

    expect(buildCount, 1);

    first.markMayNeedRebuild();
    await tester.pump();

    expect(buildCount, 2);
  });
  testWidgets('can queue multiple mayRebuilds at once', (tester) async {
    final firstSpy = ShouldRebuildMock();
    final secondSpy = ShouldRebuildMock();
    MayRebuildState first;
    MayRebuildState second;
    var buildCount = 0;

    await tester.pumpWidget(
      HookBuilder(builder: (c, h) {
        buildCount++;
        first = h.use(MayRebuild(firstSpy));
        second = h.use(MayRebuild(secondSpy));

        return Container();
      }),
    );

    verifyNoMoreInteractions(firstSpy);
    verifyNoMoreInteractions(secondSpy);
    expect(buildCount, 1);

    first.markMayNeedRebuild();
    when(firstSpy()).thenReturn(false);
    second.markMayNeedRebuild();
    when(secondSpy()).thenReturn(false);

    await tester.pump();

    expect(buildCount, 1);
    verifyInOrder([
      firstSpy(),
      secondSpy(),
    ]);
    verifyNoMoreInteractions(firstSpy);
    verifyNoMoreInteractions(secondSpy);

    first.markMayNeedRebuild();
    when(firstSpy()).thenReturn(true);
    second.markMayNeedRebuild();
    when(secondSpy()).thenReturn(false);

    await tester.pump();

    expect(buildCount, 2);
    verify(firstSpy()).called(1);
    verifyNoMoreInteractions(firstSpy);
    verifyNoMoreInteractions(secondSpy);
  });
  testWidgets('pre-build-abort', (tester) async {
    var buildCount = 0;
    final notifier = ValueNotifier(0);

    await tester.pumpWidget(
      HookBuilder(builder: (c, h) {
        buildCount++;
        final value = h.use(IsPositiveHook(notifier));

        return Text('$value', textDirection: TextDirection.ltr);
      }),
    );

    expect(buildCount, 1);
    expect(find.text('true'), findsOneWidget);
    expect(find.text('false'), findsNothing);

    notifier.value = -10;

    await tester.pump();

    expect(buildCount, 2);
    expect(find.text('false'), findsOneWidget);
    expect(find.text('true'), findsNothing);

    notifier.value = -20;

    await tester.pump();

    expect(buildCount, 2);
    expect(find.text('false'), findsOneWidget);
    expect(find.text('true'), findsNothing);

    notifier.value = 20;

    await tester.pump();

    expect(buildCount, 3);
    expect(find.text('true'), findsOneWidget);
    expect(find.text('false'), findsNothing);
  });
  testWidgets('setState then markMayNeedBuild still force build',
      (tester) async {
    var buildCount = 0;
    final notifier = ValueNotifier(0);

    await tester.pumpWidget(
      HookBuilder(builder: (c, h) {
        buildCount++;
        h.useListenable(notifier);
        final value = h.use(IsPositiveHook(notifier));

        return Text('$value', textDirection: TextDirection.ltr);
      }),
    );

    expect(buildCount, 1);
    expect(find.text('true'), findsOneWidget);
    expect(find.text('false'), findsNothing);

    notifier.value++;
    await tester.pump();

    expect(buildCount, 2);
    expect(find.text('true'), findsOneWidget);
    expect(find.text('false'), findsNothing);
  });
  testWidgets('markMayNeedBuild then widget rebuild forces build',
      (tester) async {
    var buildCount = 0;
    final notifier = ValueNotifier(0);

    Widget build() {
      return HookBuilder(builder: (c, h) {
        buildCount++;
        final value = h.use(IsPositiveHook(notifier));

        return Text('$value', textDirection: TextDirection.ltr);
      });
    }

    await tester.pumpWidget(build());

    expect(buildCount, 1);
    expect(find.text('true'), findsOneWidget);
    expect(find.text('false'), findsNothing);

    notifier.value++;
    await tester.pumpWidget(build());

    expect(buildCount, 2);
    expect(find.text('true'), findsOneWidget);
    expect(find.text('false'), findsNothing);
  });
  testWidgets('markMayNeedBuild then didChangeDepencies forces build',
      (tester) async {
    var buildCount = 0;
    final notifier = ValueNotifier(0);

    final child = HookBuilder(builder: (c, h) {
      buildCount++;
      Directionality.of(c);
      final value = h.use(IsPositiveHook(notifier));

      return Text('$value', textDirection: TextDirection.ltr);
    });

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: child,
      ),
    );

    expect(buildCount, 1);
    expect(find.text('true'), findsOneWidget);
    expect(find.text('false'), findsNothing);

    notifier.value++;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: child,
      ),
    );

    expect(buildCount, 2);
    expect(find.text('true'), findsOneWidget);
    expect(find.text('false'), findsNothing);
  });
}

class IsPositiveHook extends Hook<bool> {
  const IsPositiveHook(this.notifier);

  final ValueNotifier<int> notifier;

  @override
  IsPositiveHookState createState() {
    return IsPositiveHookState();
  }
}

class IsPositiveHookState extends HookState<bool, IsPositiveHook> {
  bool dirty = true;
  bool value;

  @override
  void initHook() {
    super.initHook();
    value = hook.notifier.value >= 0;
    hook.notifier.addListener(listener);
  }

  void listener() {
    dirty = true;
    markMayNeedRebuild();
  }

  @override
  bool shouldRebuild() {
    if (dirty) {
      dirty = false;
      final newValue = hook.notifier.value >= 0;
      if (newValue != value) {
        value = newValue;
        return true;
      }
    }
    return false;
  }

  @override
  bool build(BuildContext context) {
    if (dirty) {
      dirty = false;
      value = hook.notifier.value >= 0;
    }
    return value;
  }

  @override
  void dispose() {
    hook.notifier.removeListener(listener);
    super.dispose();
  }
}

class MayRebuild extends Hook<MayRebuildState> {
  const MayRebuild([this.shouldRebuild]);

  final ShouldRebuildMock shouldRebuild;

  @override
  MayRebuildState createState() {
    return MayRebuildState();
  }
}

class MayRebuildState extends HookState<MayRebuildState, MayRebuild> {
  @override
  bool shouldRebuild() {
    if (hook.shouldRebuild == null) {
      return super.shouldRebuild();
    }
    return hook.shouldRebuild();
  }

  @override
  MayRebuildState build(BuildContext context) => this;
}

class ShouldRebuildMock extends Mock {
  bool call();
}
