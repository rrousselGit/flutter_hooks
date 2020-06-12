import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('useValueListenable throws with null', (tester) async {
    await expectPump(
        () => tester.pumpWidget(HookBuilder(
              builder: (context) {
                useValueListenable<void>(null);
                return Container();
              },
            )),
        throwsAssertionError);
  });
  testWidgets('useValueListenable', (tester) async {
    var listenable = ValueNotifier(0);
    int result;

    pump() => tester.pumpWidget(HookBuilder(
          builder: (context) {
            result = useValueListenable(listenable);
            return Container();
          },
        ));

    await pump();

    final element = tester.firstElement(find.byType(HookBuilder));

    expect(result, 0);
    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, true);
    expect(element.dirty, false);
    listenable.value++;
    expect(element.dirty, true);
    await tester.pump();
    expect(result, 1);
    expect(element.dirty, false);

    final previousListenable = listenable;
    listenable = ValueNotifier(0);

    await pump();

    expect(result, 0);
    // ignore: invalid_use_of_protected_member
    expect(previousListenable.hasListeners, false);
    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, true);
    expect(element.dirty, false);
    listenable.value++;
    expect(element.dirty, true);
    await tester.pump();
    expect(result, 1);
    expect(element.dirty, false);

    await tester.pumpWidget(const SizedBox());

    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, false);

    listenable.dispose();
    previousListenable.dispose();
  });
}
