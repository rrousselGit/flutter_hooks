import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  Widget Function(BuildContext) snapshotText(Future<String> stream,
      {String initialData}) {
    return (context) {
      final snapshot = useFuture(stream, initialData: initialData);
      return Text(snapshot.toString(), textDirection: TextDirection.ltr);
    };
  }

  testWidgets('gracefully handles transition from null future',
      (WidgetTester tester) async {
    await tester.pumpWidget(HookBuilder(builder: snapshotText(null)));
    expect(find.text('AsyncSnapshot<String>(ConnectionState.none, null, null)'),
        findsOneWidget);
    final completer = Completer<String>();
    await tester
        .pumpWidget(HookBuilder(builder: snapshotText(completer.future)));
    expect(
        find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'),
        findsOneWidget);
  });
  testWidgets('gracefully handles transition to null future',
      (WidgetTester tester) async {
    final completer = Completer<String>();
    await tester
        .pumpWidget(HookBuilder(builder: snapshotText(completer.future)));
    expect(
        find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'),
        findsOneWidget);
    await tester.pumpWidget(HookBuilder(builder: snapshotText(null)));
    expect(find.text('AsyncSnapshot<String>(ConnectionState.none, null, null)'),
        findsOneWidget);
    completer.complete('hello');
    await eventFiring(tester);
    expect(find.text('AsyncSnapshot<String>(ConnectionState.none, null, null)'),
        findsOneWidget);
  });
  testWidgets('gracefully handles transition to other future',
      (WidgetTester tester) async {
    final completerA = Completer<String>();
    final completerB = Completer<String>();
    await tester
        .pumpWidget(HookBuilder(builder: snapshotText(completerA.future)));
    expect(
        find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'),
        findsOneWidget);
    await tester
        .pumpWidget(HookBuilder(builder: snapshotText(completerB.future)));
    expect(
        find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'),
        findsOneWidget);
    completerB.complete('B');
    completerA.complete('A');
    await eventFiring(tester);
    expect(find.text('AsyncSnapshot<String>(ConnectionState.done, B, null)'),
        findsOneWidget);
  });
  testWidgets('tracks life-cycle of Future to success',
      (WidgetTester tester) async {
    final completer = Completer<String>();
    await tester
        .pumpWidget(HookBuilder(builder: snapshotText(completer.future)));
    expect(
        find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'),
        findsOneWidget);
    completer.complete('hello');
    await eventFiring(tester);
    expect(
        find.text('AsyncSnapshot<String>(ConnectionState.done, hello, null)'),
        findsOneWidget);
  });
  testWidgets('tracks life-cycle of Future to error',
      (WidgetTester tester) async {
    final completer = Completer<String>();
    await tester
        .pumpWidget(HookBuilder(builder: snapshotText(completer.future)));
    expect(
        find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'),
        findsOneWidget);
    completer.completeError('bad');
    await eventFiring(tester);
    expect(find.text('AsyncSnapshot<String>(ConnectionState.done, null, bad)'),
        findsOneWidget);
  });
  testWidgets('runs the builder using given initial data',
      (WidgetTester tester) async {
    await tester.pumpWidget(HookBuilder(
      builder: snapshotText(
        null,
        initialData: 'I',
      ),
    ));
    expect(find.text('AsyncSnapshot<String>(ConnectionState.none, I, null)'),
        findsOneWidget);
  });
  testWidgets('ignores initialData when reconfiguring',
      (WidgetTester tester) async {
    await tester.pumpWidget(HookBuilder(
      builder: snapshotText(
        null,
        initialData: 'I',
      ),
    ));
    expect(find.text('AsyncSnapshot<String>(ConnectionState.none, I, null)'),
        findsOneWidget);
    final completer = Completer<String>();
    await tester.pumpWidget(HookBuilder(
      builder: snapshotText(
        completer.future,
        initialData: 'Ignored',
      ),
    ));
    expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting, I, null)'),
        findsOneWidget);
  });
}

Future<void> eventFiring(WidgetTester tester) async {
  await tester.pump(Duration.zero);
}
