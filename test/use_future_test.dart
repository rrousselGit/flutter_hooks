import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('default preserve state, changing future keeps previous value',
      (tester) async {
    AsyncSnapshot<int> value;
    Widget Function(BuildContext) builder(Future<int> stream) {
      return (context) {
        value = useFuture(stream);
        return Container();
      };
    }

    var future = Future.value(0);
    await tester.pumpWidget(HookBuilder(builder: builder(future)));
    expect(value.data, null);
    await tester.pumpWidget(HookBuilder(builder: builder(future)));
    expect(value.data, 0);

    future = Future.value(42);
    await tester.pumpWidget(HookBuilder(builder: builder(future)));
    expect(value.data, 0);
    await tester.pumpWidget(HookBuilder(builder: builder(future)));
    expect(value.data, 42);
  });
  testWidgets('If preserveState == false, changing future resets value',
      (tester) async {
    AsyncSnapshot<int> value;
    Widget Function(BuildContext) builder(Future<int> stream) {
      return (context) {
        value = useFuture(stream, preserveState: false);
        return Container();
      };
    }

    var future = Future.value(0);
    await tester.pumpWidget(HookBuilder(builder: builder(future)));
    expect(value.data, null);
    await tester.pumpWidget(HookBuilder(builder: builder(future)));
    expect(value.data, 0);

    future = Future.value(42);
    await tester.pumpWidget(HookBuilder(builder: builder(future)));
    expect(value.data, null);
    await tester.pumpWidget(HookBuilder(builder: builder(future)));
    expect(value.data, 42);
  });

  Widget Function(BuildContext) snapshotText(Future<String> stream,
      {String initialData}) {
    return (context) {
      final snapshot = useFuture(stream, initialData: initialData);
      return Text(snapshot.toString(), textDirection: TextDirection.ltr);
    };
  }

  testWidgets('gracefully handles transition from null future', (tester) async {
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
  testWidgets('gracefully handles transition to null future', (tester) async {
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
  testWidgets('gracefully handles transition to other future', (tester) async {
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
  testWidgets('tracks life-cycle of Future to success', (tester) async {
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
  testWidgets('tracks life-cycle of Future to error', (tester) async {
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
  testWidgets('runs the builder using given initial data', (tester) async {
    await tester.pumpWidget(HookBuilder(
      builder: snapshotText(
        null,
        initialData: 'I',
      ),
    ));
    expect(find.text('AsyncSnapshot<String>(ConnectionState.none, I, null)'),
        findsOneWidget);
  });
  testWidgets('ignores initialData when reconfiguring', (tester) async {
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
