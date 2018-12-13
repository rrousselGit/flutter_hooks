import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/hook.dart';
import 'package:mockito/mockito.dart';

import 'mock.dart';

void main() {
  testWidgets('simple build', (tester) async {
    final fn = Func1<HookContext, Widget>();
    when(fn.call(any)).thenAnswer((_) {
      return Container();
    });

    final createBuilder = () => HookBuilder(builder: fn.call);
    final _builder = createBuilder();

    await tester.pumpWidget(_builder);

    verify(fn.call(any)).called(1);

    await tester.pumpWidget(_builder);
    verifyNever(fn.call(any));

    await tester.pumpWidget(createBuilder());
    verify(fn.call(any)).called(1);
  });
}
