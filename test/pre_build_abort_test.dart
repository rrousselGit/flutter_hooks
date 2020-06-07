import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pre-build-abort', (tester) async {
    var buildCount = 0;
    final notifier = ValueNotifier(0);

    await tester.pumpWidget(
      HookBuilder(builder: (c) {
        buildCount++;
        final value = Hook.use(IsPositiveHook(notifier));

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
      HookBuilder(builder: (c) {
        buildCount++;
        useListenable(notifier);
        final value = Hook.use(IsPositiveHook(notifier));

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
      return HookBuilder(builder: (c) {
        buildCount++;
        final value = Hook.use(IsPositiveHook(notifier));

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

    final child = HookBuilder(builder: (c) {
      buildCount++;
      Directionality.of(c);
      final value = Hook.use(IsPositiveHook(notifier));

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
    markMayNeedRebuild(() {
      dirty = false;
      final newValue = hook.notifier.value >= 0;
      if (newValue != value) {
        value = newValue;
        return true;
      }
      return false;
    });
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
