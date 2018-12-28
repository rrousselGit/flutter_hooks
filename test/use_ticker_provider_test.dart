import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('useSingleTickerProvider basic', (tester) async {
    TickerProvider provider;

    await tester.pumpWidget(TickerMode(
      enabled: true,
      child: HookBuilder(builder: (context) {
        provider = useSingleTickerProvider();
        return Container();
      }),
    ));

    final animationController = AnimationController(
        vsync: provider, duration: const Duration(seconds: 1))
      ..forward();

    expect(() => AnimationController(vsync: provider), throwsFlutterError);

    animationController.dispose();

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('useSingleTickerProvider unused', (tester) async {
    await tester.pumpWidget(HookBuilder(builder: (context) {
      useSingleTickerProvider();
      return Container();
    }));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('useSingleTickerProvider still active', (tester) async {
    TickerProvider provider;

    await tester.pumpWidget(TickerMode(
      enabled: true,
      child: HookBuilder(builder: (context) {
        provider = useSingleTickerProvider();
        return Container();
      }),
    ));

    final animationController = AnimationController(
        vsync: provider, duration: const Duration(seconds: 1));

    try {
      animationController.forward();
      await expectPump(
        () => tester.pumpWidget(const SizedBox()),
        throwsFlutterError,
      );
    } finally {
      animationController.dispose();
    }
  });

  testWidgets('useSingleTickerProvider pass down keys', (tester) async {
    TickerProvider provider;
    List keys;

    await tester.pumpWidget(HookBuilder(builder: (context) {
      provider = useSingleTickerProvider(keys: keys);
      return Container();
    }));

    final previousProvider = provider;
    keys = <dynamic>[];

    await tester.pumpWidget(HookBuilder(builder: (context) {
      provider = useSingleTickerProvider(keys: keys);
      return Container();
    }));

    expect(previousProvider, isNot(provider));
  });
}
