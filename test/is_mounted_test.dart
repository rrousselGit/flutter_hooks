import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('useIsMounted', (tester) async {
    IsMounted isMounted;

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        isMounted = useIsMounted();
        return Container();
      },
    ));

    expect(isMounted(), true);

    await tester.pumpWidget(Container());

    expect(isMounted(), false);
  });
}
