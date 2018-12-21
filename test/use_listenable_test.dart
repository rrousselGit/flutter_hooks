import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('useListenable throws with null', (tester) async {
    await expectPump(
        () => tester.pumpWidget(HookBuilder(
              builder: (context) {
                context.useListenable(null);
                return Container();
              },
            )),
        throwsAssertionError);
  });
  testWidgets('useListenable', (tester) async {
    var listenable = ValueNotifier(0);

    pump() => tester.pumpWidget(HookBuilder(
          builder: (context) {
            context.useListenable(listenable);
            return Container();
          },
        ));

    await pump();

    final element = tester.firstElement(find.byType(HookBuilder));

    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, true);
    expect(element.dirty, false);
    listenable.value++;
    expect(element.dirty, true);
    await tester.pump();
    expect(element.dirty, false);

    final previousListenable = listenable;
    listenable = ValueNotifier(0);

    await pump();

    // ignore: invalid_use_of_protected_member
    expect(previousListenable.hasListeners, false);
    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, true);
    expect(element.dirty, false);
    listenable.value++;
    expect(element.dirty, true);
    await tester.pump();
    expect(element.dirty, false);

    await tester.pumpWidget(const SizedBox());

    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, false);

    listenable.dispose();
    previousListenable.dispose();
  });
}
