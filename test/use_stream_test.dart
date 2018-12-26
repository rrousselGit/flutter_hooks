import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

/// port of [StreamBuilder]
///
void main() {
  Widget Function(BuildContext) snapshotText(Stream<String> stream,
      {String initialData}) {
    return (context) {
      final snapshot = useStream(stream, initialData: initialData);
      return Text(snapshot.toString(), textDirection: TextDirection.ltr);
    };
  }

  testWidgets('gracefully handles transition from null stream',
      (WidgetTester tester) async {
    await tester.pumpWidget(HookBuilder(builder: snapshotText(null)));
    expect(find.text('AsyncSnapshot<String>(ConnectionState.none, null, null)'),
        findsOneWidget);
    final controller = StreamController<String>();
    await tester
        .pumpWidget(HookBuilder(builder: snapshotText(controller.stream)));
    expect(
        find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'),
        findsOneWidget);
  });
  testWidgets('gracefully handles transition to null stream',
      (WidgetTester tester) async {
    final controller = StreamController<String>();
    await tester
        .pumpWidget(HookBuilder(builder: snapshotText(controller.stream)));
    expect(
        find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'),
        findsOneWidget);
    await tester.pumpWidget(HookBuilder(builder: snapshotText(null)));
    expect(find.text('AsyncSnapshot<String>(ConnectionState.none, null, null)'),
        findsOneWidget);
  });
  testWidgets('gracefully handles transition to other stream',
      (WidgetTester tester) async {
    final controllerA = StreamController<String>();
    final controllerB = StreamController<String>();
    await tester
        .pumpWidget(HookBuilder(builder: snapshotText(controllerA.stream)));
    expect(
        find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'),
        findsOneWidget);
    await tester
        .pumpWidget(HookBuilder(builder: snapshotText(controllerB.stream)));
    controllerB.add('B');
    controllerA.add('A');
    await eventFiring(tester);
    expect(find.text('AsyncSnapshot<String>(ConnectionState.active, B, null)'),
        findsOneWidget);
  });
  testWidgets('tracks events and errors of stream until completion',
      (WidgetTester tester) async {
    final controller = StreamController<String>();
    await tester
        .pumpWidget(HookBuilder(builder: snapshotText(controller.stream)));
    expect(
        find.text('AsyncSnapshot<String>(ConnectionState.waiting, null, null)'),
        findsOneWidget);
    controller..add('1')..add('2');
    await eventFiring(tester);
    expect(find.text('AsyncSnapshot<String>(ConnectionState.active, 2, null)'),
        findsOneWidget);
    controller
      ..add('3')
      ..addError('bad');
    await eventFiring(tester);
    expect(
        find.text('AsyncSnapshot<String>(ConnectionState.active, null, bad)'),
        findsOneWidget);
    controller.add('4');
    await controller.close();
    await eventFiring(tester);
    expect(find.text('AsyncSnapshot<String>(ConnectionState.done, 4, null)'),
        findsOneWidget);
  });
  testWidgets('runs the builder using given initial data',
      (WidgetTester tester) async {
    final controller = StreamController<String>();
    await tester.pumpWidget(HookBuilder(
      builder: snapshotText(controller.stream, initialData: 'I'),
    ));
    expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting, I, null)'),
        findsOneWidget);
  });
  testWidgets('ignores initialData when reconfiguring',
      (WidgetTester tester) async {
    await tester.pumpWidget(HookBuilder(
      builder: snapshotText(null, initialData: 'I'),
    ));
    expect(find.text('AsyncSnapshot<String>(ConnectionState.none, I, null)'),
        findsOneWidget);
    final controller = StreamController<String>();
    await tester.pumpWidget(HookBuilder(
      builder: snapshotText(controller.stream, initialData: 'Ignored'),
    ));
    expect(find.text('AsyncSnapshot<String>(ConnectionState.waiting, I, null)'),
        findsOneWidget);
  });
}

Future<void> eventFiring(WidgetTester tester) async {
  await tester.pump(Duration.zero);
}
