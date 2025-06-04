import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('useThrottled', () {
    testWidgets('no update when tapping multiple times', (tester) async {
      await tester.runAsync<void>(() async {
        await tester.pumpWidget(const _UseThrottledTestWidget());

        final text = find.byType(GestureDetector);
        expect(find.text('1'), findsOneWidget);

        await tester.tap(text);
        await tester.pump();

        expect(find.text('2'), findsOneWidget);

        await tester.tap(text);
        await tester.pump();
        expect(find.text('2'), findsOneWidget);

        await tester.tap(text);
        await tester.pump();
        expect(find.text('2'), findsOneWidget);

        await tester.tap(text);
        await tester.pump();
        expect(find.text('2'), findsOneWidget);
      });
    });

    testWidgets('update number after duration', (tester) async {
      await tester.runAsync<void>(() async {
        await tester.pumpWidget(const _UseThrottledTestWidget());

        final text = find.byType(GestureDetector);
        expect(find.text('1'), findsOneWidget);

        await tester.pumpAndSettle(_duration);
        await Future<void>.delayed(_duration);

        await tester.tap(text);
        await tester.pump();

        expect(find.text('2'), findsOneWidget);
      });
    });
  });
}

class _UseThrottledTestWidget extends HookWidget {
  const _UseThrottledTestWidget();

  @override
  Widget build(BuildContext context) {
    final textNumber = useState(1);
    final throttle = useThrottled(duration: _duration);

    void updateText() {
      textNumber.value++;
    }

    return MaterialApp(
      home: GestureDetector(
        onTap: () => throttle(updateText),
        child: Text(textNumber.value.toString()),
      ),
    );
  }
}

const _duration = Duration(milliseconds: 500);
