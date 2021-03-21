import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

class DidBuildHookTest extends Hook<void> {
  const DidBuildHookTest({
    required this.callback,
    List<Object?>? keys,
  }) : super(keys: keys);

  final VoidCallback callback;

  @override
  DidBuildHookStateTest createState() => DidBuildHookStateTest();
}

class DidBuildHookStateTest extends HookState<void, DidBuildHookTest> {
  @override
  void initHook() {
    super.initHook();
    setDidBuildListener(hook.callback);
  }

  @override
  void build(BuildContext context) {
    //no op
  }
}

void main() {
  testWidgets('useDidBuild', (tester) async {
    var isCalled = false;
    final hook = DidBuildHookTest(callback: () {
      isCalled = true;
    });

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        use(hook);
        return Container();
      },
    ));

    expect(isCalled, true);
  });
}
