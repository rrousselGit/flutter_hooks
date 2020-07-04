import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('useAnimation throws with null', (tester) async {
    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        useAnimation<void>(null);
        return Container();
      },
    ));

    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('useAnimation', (tester) async {
    var listenable = AnimationController(vsync: tester);
    double result;

    Future<void> pump() {
      return tester.pumpWidget(HookBuilder(
        builder: (context) {
          result = useAnimation(listenable);
          return Container();
        },
      ));
    }

    await pump();

    final element = tester.firstElement(find.byType(HookBuilder));

    expect(result, 0);
    expect(element.dirty, false);
    listenable.value++;
    expect(element.dirty, true);
    await tester.pump();
    expect(result, 1);
    expect(element.dirty, false);

    final previousListenable = listenable;
    listenable = AnimationController(vsync: tester);

    await pump();

    expect(result, 0);
    expect(element.dirty, false);
    previousListenable.value++;
    expect(element.dirty, false);
    listenable.value++;
    expect(element.dirty, true);
    await tester.pump();
    expect(result, 1);
    expect(element.dirty, false);

    await tester.pumpWidget(const SizedBox());

    listenable.dispose();
    previousListenable.dispose();
  });
}
