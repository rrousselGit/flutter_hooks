import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_mobx_hooks/flutter_mobx_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_store.dart';

void main() {
  testWidgets('useWhen', (tester) async {
    var build = 0;
    var value = 0;
    final store = Counter();

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        useWhen((_) => store.value == 2, () {
          value = store.value;
        });
        build = store.value;
        return Container();
      },
    ));

    expect(value, 0);
    expect(build, 0);
    expect(store.value, 0);
    store.increment();
    expect(value, 0);
    expect(build, 0);
    expect(store.value, 1);
    store.increment();
    expect(value, 2);
    expect(store.value, 2);
    expect(build, 0);
    store.increment();
    expect(value, 2);
    expect(store.value, 3);
    expect(build, 0);
  });

  testWidgets('useWhen disposed', (tester) async {
    var build = 0;
    var value = 0;
    final store = Counter();

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        useWhen((_) => store.value > 0, () {
          value++;
        });
        build++;
        return Container();
      },
    ));

    expect(value, 0);
    expect(build, 1);
    expect(store.value, 0);
    store.increment();
    expect(value, 1);
    expect(build, 1);
    expect(store.value, 1);
    await tester.pumpWidget(const SizedBox());
    store.increment();
    expect(value, 1);
    expect(build, 1);
    expect(store.value, 2);
  });
}
