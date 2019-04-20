import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

Widget build(int value) => HookBuilder(
      builder: (context) =>
          Text(usePrevious(value).toString(), textDirection: TextDirection.ltr),
    );
void main() {
  group('usePrevious', () {
    testWidgets('default value is null', (tester) async {
      await tester.pumpWidget(build(0));

      expect(find.text('null'), findsOneWidget);
    });
    testWidgets('subsequent build returns previous value', (tester) async {
      await tester.pumpWidget(build(0));
      await tester.pumpWidget(build(1));

      expect(find.text('0'), findsOneWidget);

      await tester.pumpWidget(build(1));

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(build(2));
      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(build(3));
      expect(find.text('2'), findsOneWidget);
    });
  });
}
