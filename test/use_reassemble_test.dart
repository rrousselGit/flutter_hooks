import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('useReassemble null callback throws', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (c) {
        useReassemble(null);
        return Container();
      }),
    );

    expect(tester.takeException(), isAssertionError);
  });

  testWidgets("hot-reload calls useReassemble's callback", (tester) async {
    final reassemble = MockReassemble();

    await tester.pumpWidget(HookBuilder(builder: (context) {
      useReassemble(reassemble);
      return Container();
    }));

    verifyNoMoreInteractions(reassemble);

    hotReload(tester);
    await tester.pump();

    verify(reassemble()).called(1);
    verifyNoMoreInteractions(reassemble);
  });
}
