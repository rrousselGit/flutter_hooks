import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/src/framework.dart';
import 'package:flutter_hooks/src/hooks.dart';
import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        final listenable = ValueNotifier<int>(42);
        useListenableSelector<bool>(listenable, () => listenable.value.isOdd);
        return const SizedBox();
      },
    ));

    final element = tester.element(find.byType(HookBuilder));

    expect(
      element
          .toDiagnosticsNode(style: DiagnosticsTreeStyle.offstage)
          .toStringDeep(),
      equalsIgnoringHashCodes(
        'HookBuilder\n'
        ' │ useListenableSelector<bool>: false\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n'
        '',
      ),
    );
  });
  testWidgets('useListenableSelector', (tester) async {
    late HookElement element;
    late ValueNotifier<int> listenable;
    late bool isOdd;

    Future<void> pump() {
      return tester.pumpWidget(HookBuilder(
        builder: (context) {
          element = context as HookElement;
          listenable = useState(42);
          isOdd =
              useListenableSelector(listenable, () => listenable.value.isOdd);
          return Container();
        },
      ));
    }

    await pump();
    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, true);
    expect(listenable.value, 42);
    expect(isOdd, false);
    expect(element.dirty, false);

    listenable.value++;
    expect(element.dirty, true);
    await tester.pump();
    expect(listenable.value, 43);
    expect(isOdd, true);
    expect(element.dirty, false);

    listenable.value = listenable.value + 2;
    expect(element.dirty, true);
    await tester.pump();
    expect(listenable.value, 45);
    expect(isOdd, true);
    expect(element.dirty, false);

    listenable.value++;
    await tester.pump();
    expect(listenable.value, 46);
    expect(isOdd, false);
    expect(element.dirty, false);

    await tester.pumpWidget(const SizedBox());
    // ignore: invalid_use_of_protected_member
    expect(() => listenable.hasListeners, throwsFlutterError);
  });
}
