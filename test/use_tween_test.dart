import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  group('useTween', () {
    testWidgets('useTween<double> basic', (tester) async {
      Tween<double> tween;

      await tester.pumpWidget(HookBuilder(
        builder: (context) {
          tween = useTween<double>(42.0);
          return Container();
        },
      ));

      expect(tween.begin, 42);
      expect(tween.end, 42);
      expect(tween.transform(0.5), 42);

      await tester.pump();

      expect(tween.begin, 42);
      expect(tween.end, 42);
      expect(tween.transform(0.5), 42);

      // dispose
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('useTween<double> value updated', (tester) async {
      Tween<double> tween;

      await tester.pumpWidget(HookBuilder(
        builder: (context) {
          tween = useTween<double>(42.0);
          return Container();
        },
      ));

      expect(tween.begin, 42);
      expect(tween.end, 42);
      expect(tween.transform(0.5), 42);

      await tester.pumpWidget(HookBuilder(
        builder: (context) {
          tween = useTween<double>(84.0);
          return Container();
        },
      ));

      expect(tween.begin, 42);
      expect(tween.end, 84);
      expect(tween.transform(0.5), 63);

      // dispose
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('useTween<double> lerp updated', (tester) async {
      Tween<double> tween;

      await tester.pumpWidget(HookBuilder(
        builder: (context) {
          tween = useTween<double>(42.0, lerp: (from,to,t) => to * 0.5);
          return Container();
        },
      ));

      expect(tween.begin, 42);
      expect(tween.end, 42);
      expect(tween.transform(0.5), 21);

      await tester.pumpWidget(HookBuilder(
         builder: (context) {
          tween = useTween<double>(42.0, lerp: (from,to,t) => to * 2.0);
          return Container();
        },
      ));

      expect(tween.begin, 42);
      expect(tween.end, 42);
      expect(tween.transform(0.5), 84);

      // dispose
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('instance stays the same when value doesn\'t change',
        (tester) async {
      Tween<double> state;
      Tween<double> previous;

      await tester.pumpWidget(HookBuilder(
        builder: (context) {
          previous = useTween<double>(42.0);
          return Container();
        },
      ));

      await tester.pumpWidget(HookBuilder(
        builder: (context) {
          state = useTween<double>(42.0);
          return Container();
        },
      ));

      expect(state, previous);
    });
  });
}
