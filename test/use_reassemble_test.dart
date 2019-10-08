import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('useReassemble null callback throws', (tester) async {
    await expectPump(
      () => tester.pumpWidget(HookBuilder(builder: (c) {
        useReassemble(null);
        return Container();
      })),
      throwsAssertionError,
    );
  });

  testWidgets('hot-reload calls useReassemble\'s callback', (tester) async {
    final reassemble = Func0<void>();
    await tester.pumpWidget(HookBuilder(builder: (context) {
      useReassemble(reassemble);
      return Container();
    }));

    verifyNoMoreInteractions(reassemble);

    hotReload(tester);
    await tester.pump();

    verifyInOrder([
      reassemble.call(),
    verify(reassemble()).called(1);
    verifyNoMoreInteractions(reassemble);
  });

}
