import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_mobx_hooks/flutter_mobx_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_store.dart';

void main() {
  testWidgets('useObserver', (tester) async {
    var value = 0;
    final store = Counter();

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        useObserver();
        value = store.value;
        return Container();
      },
    ));

    expect(value, 0);
    store.increment();
    await tester.pump();
    expect(value, 1);
  });
}
