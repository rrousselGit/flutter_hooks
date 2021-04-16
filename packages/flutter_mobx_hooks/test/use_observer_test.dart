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

  testWidgets('useObserver disposed', (tester) async {
    var value = 0;
    var build = 0;
    final store = Counter();

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        useObserver();
        value = store.value;
        build++;
        return Container();
      },
    ));

    expect(value, 0);
    expect(build, 1);
    store.increment();
    await tester.pump();
    expect(value, 1);
    expect(build, 2);
    await tester.pumpWidget(const SizedBox());
    store.increment();
    await tester.pump();
    expect(value, 1);
    expect(build, 2);
  });

  testWidgets('useObserver nested', (tester) async {
    var value = 0;
    var valueNested = 0;
    var build = 0;
    var buildNested = 0;
    final store = Counter();

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        useObserver();
        value = store.value;
        build++;
        return HookBuilder(
          builder: (context) {
            useObserver();
            valueNested = store.value2;
            buildNested++;
            return Container();
          },
        );
      },
    ));

    expect(value, 0);
    expect(build, 1);
    expect(valueNested, 0);
    expect(buildNested, 1);
    store.increment();
    await tester.pump();
    expect(value, 1);
    expect(build, 2);
    expect(valueNested, 0);
    expect(buildNested, 2);
    store.increment2();
    await tester.pump();
    expect(value, 1);
    expect(build, 2);
    expect(valueNested, 1);
    expect(buildNested, 3);
  });
}
