import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

final callback = Func0<VoidCallback>();

Widget builder() => HookBuilder(builder: (context) {
      useReassemble(callback);
      return Container();
    });

void main() {
  tearDown(() {
    reset(callback);
  });

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
    ]);
    verifyNoMoreInteractions(reassemble);
  });

}
