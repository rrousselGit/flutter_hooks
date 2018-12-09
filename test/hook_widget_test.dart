import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/hook.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _MockHook<R> extends Hook<R> {
  final _MockHookState<R> _state;

  const _MockHook([this._state]);

  @override
  _MockHookState<R> createState() => _state ?? _MockHookState();
}

class _MockHookState<R> extends Mock implements HookState<R, _MockHook<R>> {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) {
    /// official implementation of [Diagnosticable]
    return toDiagnosticsNode(style: DiagnosticsTreeStyle.singleLine)
        .toString(minLevel: minLevel);
  }
}

void main() {
  testWidgets('do not throw', (tester) {
    tester.pumpWidget(HookBuilder(
      builder: (context) {
        return Container();
      },
    ));
  });
  testWidgets('simple hook', (tester) async {
    final state = _MockHookState<int>();
    when(state.build(any)).thenReturn(42);

    int value;
    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        value = context.useHook(_MockHook(state));
        return Container();
      },
    ));

    expect(value, equals(42));
  });
}
