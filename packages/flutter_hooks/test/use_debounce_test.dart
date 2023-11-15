import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useDebounced(42, timeout: const Duration(milliseconds: 500));
        return const SizedBox();
      }),
    );

    // await the debouncer timeout.
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    final element = tester.element(find.byType(HookBuilder));

    expect(
      element
          .toDiagnosticsNode(style: DiagnosticsTreeStyle.offstage)
          .toStringDeep(),
      equalsIgnoringHashCodes(
        'HookBuilder\n'
        ' │ useDebounced<int>: 42\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  group('useDebounced', () {
    testWidgets('default value is null', (tester) async {
      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          return Text(
            useDebounced(
              null,
              timeout: const Duration(milliseconds: 500),
            ).value.toString(),
            textDirection: TextDirection.ltr,
          );
        }),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.text('null'), findsOneWidget);
    });
    testWidgets('basic', (tester) async {
      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            final textValueNotifier = useState('Hello');
            final debouncedNotifier = useDebounced(
              textValueNotifier.value,
              timeout: const Duration(milliseconds: 500),
            );

            useEffect(() {
              textValueNotifier.value = 'World';
              return null;
            }, [textValueNotifier.value]);

            return Text(
              debouncedNotifier.value.toString(),
              textDirection: TextDirection.ltr,
            );
          },
        ),
      );

      // Ensure that the initial value displayed is 'null'
      expect(find.text('null'), findsOneWidget);

      // Ensure that after a 500ms delay, the value 'Hello' of 'textValueNotifier'
      // is reflected in 'debouncedNotifier' and displayed
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.text('Hello'), findsOneWidget);

      // Ensure that after another 500ms delay, the value 'World' assigned to
      // 'textValueNotifier' in the useEffect is reflected in 'debouncedNotifier'
      // and displayed
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.text('World'), findsOneWidget);
    });
  });
}
