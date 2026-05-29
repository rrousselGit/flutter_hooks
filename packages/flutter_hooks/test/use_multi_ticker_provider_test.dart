import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useMultiTickerProvider();
        return const SizedBox();
      }),
    );

    await tester.pump();

    final element = tester.element(find.byType(HookBuilder));

    expect(
      element.toDiagnosticsNode(style: DiagnosticsTreeStyle.offstage).toStringDeep(),
      equalsIgnoringHashCodes(
        'HookBuilder\n'
        ' │ useMultiTickerProvider\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  testWidgets('useMultiTickerProvider basic', (tester) async {
    late TickerProvider provider;

    await tester.pumpWidget(TickerMode(
      enabled: true,
      child: HookBuilder(builder: (context) {
        provider = useMultiTickerProvider();
        return Container();
      }),
    ));

    final animationControllerA = AnimationController(
      vsync: provider,
      duration: const Duration(seconds: 1),
    );
    // With a multi provider, creating additional AnimationControllers is allowed.
    final animationControllerB = AnimationController(
      vsync: provider,
      duration: const Duration(seconds: 1),
    );

    unawaited(animationControllerA.forward());
    unawaited(animationControllerB.forward());

    animationControllerA.dispose();
    animationControllerB.dispose();

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('useMultiTickerProvider unused', (tester) async {
    await tester.pumpWidget(HookBuilder(builder: (context) {
      useMultiTickerProvider();
      return Container();
    }));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('useMultiTickerProvider still active', (tester) async {
    late TickerProvider provider;

    await tester.pumpWidget(TickerMode(
      enabled: true,
      child: HookBuilder(builder: (context) {
        provider = useMultiTickerProvider();
        return Container();
      }),
    ));

    final animationController = AnimationController(
      vsync: provider,
      duration: const Duration(seconds: 1),
    );

    try {
      // ignore: unawaited_futures
      animationController.forward();

      await tester.pumpWidget(const SizedBox());

      expect(tester.takeException(), isFlutterError);
    } finally {
      animationController.dispose();
    }
  });

  testWidgets('new tickers created when TickerMode disabled are muted', (tester) async {
    late TickerProvider provider;

    await tester.pumpWidget(TickerMode(
      enabled: false,
      child: HookBuilder(builder: (context) {
        provider = useMultiTickerProvider();
        return Container();
      }),
    ));

    final animationController = AnimationController(
      vsync: provider,
      duration: const Duration(seconds: 1),
    );

    // Attempt to start the animation — when the underlying ticker is muted
    // (because TickerMode is disabled), the controller should not advance.
    unawaited(animationController.forward());
    await tester.pump(const Duration(milliseconds: 100));

    expect(animationController.value, equals(0.0));

    animationController.dispose();
  });

  testWidgets('useMultiTickerProvider pass down keys', (tester) async {
    late TickerProvider provider;
    List<Object?>? keys;

    await tester.pumpWidget(HookBuilder(builder: (context) {
      provider = useMultiTickerProvider(keys: keys);
      return Container();
    }));

    final previousProvider = provider;
    keys = [];

    await tester.pumpWidget(HookBuilder(builder: (context) {
      provider = useMultiTickerProvider(keys: keys);
      return Container();
    }));

    expect(previousProvider, isNot(provider));
  });
}
