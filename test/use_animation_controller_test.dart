import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('useAnimationController basic', (tester) async {
    AnimationController controller;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        controller = context.useAnimationController();
        return Container();
      }),
    );

    expect(controller.duration, isNull);
    expect(controller.lowerBound, 0);
    expect(controller.upperBound, 1);
    expect(controller.value, 0);
    expect(controller.animationBehavior, AnimationBehavior.normal);
    expect(controller.debugLabel, isNull);

    controller
      ..duration = const Duration(seconds: 1)
      // check has a ticker
      ..forward();

    // dispose
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('useAnimationController complex', (tester) async {
    AnimationController controller;

    TickerProvider provider;
    provider = _TickerProvider();
    when(provider.createTicker(any)).thenAnswer((_) {
      void Function(Duration) cb = _.positionalArguments[0];
      return tester.createTicker(cb);
    });

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        controller = context.useAnimationController(
          vsync: provider,
          animationBehavior: AnimationBehavior.preserve,
          duration: const Duration(seconds: 1),
          initialValue: 42,
          lowerBound: 24,
          upperBound: 84,
          debugLabel: 'Foo',
        );
        return Container();
      }),
    );

    verify(provider.createTicker(any)).called(1);
    verifyNoMoreInteractions(provider);

    // check has a ticker
    controller.forward();
    expect(controller.duration, const Duration(seconds: 1));
    expect(controller.lowerBound, 24);
    expect(controller.upperBound, 84);
    expect(controller.value, 42);
    expect(controller.animationBehavior, AnimationBehavior.preserve);
    expect(controller.debugLabel, 'Foo');

    var previousController = controller;
    provider = _TickerProvider();
    when(provider.createTicker(any)).thenAnswer((_) {
      void Function(Duration) cb = _.positionalArguments[0];
      return tester.createTicker(cb);
    });

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        controller = context.useAnimationController(
          vsync: provider,
          animationBehavior: AnimationBehavior.normal,
          duration: const Duration(seconds: 2),
          initialValue: 0,
          lowerBound: 0,
          upperBound: 0,
          debugLabel: 'Bar',
        );
        return Container();
      }),
    );

    verify(provider.createTicker(any)).called(1);
    verifyNoMoreInteractions(provider);
    expect(controller, previousController);
    expect(controller.duration, const Duration(seconds: 2));
    expect(controller.lowerBound, 24);
    expect(controller.upperBound, 84);
    expect(controller.value, 42);
    expect(controller.animationBehavior, AnimationBehavior.preserve);
    expect(controller.debugLabel, 'Foo');

    // dispose
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('switch between controlled and  uncontrolled throws',
      (tester) async {
    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        context.useAnimationController();
        return Container();
      },
    ));

    await expectPump(
      () => tester.pumpWidget(HookBuilder(
            builder: (context) {
              context.useAnimationController(vsync: tester);
              return Container();
            },
          )),
      throwsAssertionError,
    );

    await tester.pumpWidget(Container());

    // the other way around
    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        context.useAnimationController(vsync: tester);
        return Container();
      },
    ));

    await expectPump(
      () => tester.pumpWidget(HookBuilder(
            builder: (context) {
              context.useAnimationController();
              return Container();
            },
          )),
      throwsAssertionError,
    );
  });

  testWidgets('useAnimationController pass down keys', (tester) async {
    List keys;
    AnimationController controller;
    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        controller = context.useAnimationController(keys: keys);
        return Container();
      },
    ));

    final previous = controller;
    keys = <dynamic>[];

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        controller = context.useAnimationController(keys: keys);
        return Container();
      },
    ));

    expect(previous, isNot(controller));
  });
}

class _TickerProvider extends Mock implements TickerProvider {}
