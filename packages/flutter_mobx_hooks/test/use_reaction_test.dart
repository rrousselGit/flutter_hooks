import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_mobx_hooks/flutter_mobx_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';

import 'fake_store.dart';

void main() {
  testWidgets('useReaction', (tester) async {
    var build = 0;
    var value = 0;
    final store = Counter();

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        useReaction<int>((_) => store.value, (newValue) {
          value = newValue;
        });
        build = store.value;
        return Container();
      },
    ));

    expect(value, 0);
    expect(build, 0);
    store.increment();
    expect(value, 1);
    expect(build, 0);
    store.increment();
    expect(value, 2);
    expect(build, 0);
  });

  testWidgets('useReaction reaction param', (tester) async {
    var build = 0;
    var value = 0;
    final store = Counter();

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        useReaction<int>((reaction) {
          if (store.value == 1) {
            reaction.dispose();
          }
          return store.value;
        }, (newValue) {
          value = newValue;
        });
        build++;
        return Container();
      },
    ));

    expect(value, 0);
    expect(build, 1);
    store.increment();
    expect(value, 1);
    expect(build, 1);
    store.increment();
    expect(value, 1);
    expect(build, 1);
  });

  testWidgets('useReaction disposed', (tester) async {
    var build = 0;
    var value = 0;
    final store = Counter();

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        useReaction<int>((_) => store.value, (newValue) {
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

  testWidgets('useReaction update predicate', (tester) async {
    var build = 0;
    var value = 0;
    final store = Counter();

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        useReaction<int>((_) => store.value, (newValue) {
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
    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        useReaction<int>((_) => store.value2, (newValue) {
          value = newValue;
        });
        build++;
        return Container();
      },
    ));
    store.increment2();
    expect(value, store.value2);
    expect(build, 2);
    expect(store.value, 1);
    expect(store.value2, 1);
  });

  testWidgets('useReaction update effect', (tester) async {
    var build = 0;
    var value = 0;
    final store = Counter();
    // ignore: prefer_function_declarations_over_variables, avoid_types_on_closure_parameters
    final predicate = (Reaction _) => store.value;

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        useReaction<int>(predicate, (newValue) {
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
    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        useReaction<int>(predicate, (newValue) {
          value += 2;
        });
        build++;
        return Container();
      },
    ));
    store.increment();
    expect(value, 3);
    expect(build, 2);
    expect(store.value, 2);
  });
}
