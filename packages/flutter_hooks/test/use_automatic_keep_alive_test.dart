import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/src/framework.dart';
import 'package:flutter_hooks/src/hooks.dart';

import 'mock.dart';

void main() {
  group('useAutomaticKeepAlive', () {
    testWidgets('debugFillProperties', (tester) async {
      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          useAutomaticKeepAlive();
          return const SizedBox();
        }),
      );

      await tester.pump();

      final element = tester.element(find.byType(HookBuilder));

      expect(
        element
            .toDiagnosticsNode(style: DiagnosticsTreeStyle.offstage)
            .toStringDeep(),
        equalsIgnoringHashCodes(
          'HookBuilder\n'
          " │ useAutomaticKeepAlive: Instance of 'KeepAliveHandle'\n"
          ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
        ),
      );
    });

    testWidgets('keeps widget alive in a TabView', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTabController(
            length: 2,
            child: TabBarView(
              children: [
                HookBuilder(builder: (context) {
                  useAutomaticKeepAlive();
                  return Container();
                }),
                Container(),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final findKeepAlive = find.byType(AutomaticKeepAlive);
      final keepAlive = tester.element(findKeepAlive);

      expect(findKeepAlive, findsOneWidget);
      expect(
        keepAlive
            .toDiagnosticsNode(style: DiagnosticsTreeStyle.shallow)
            .toStringDeep(),
        equalsIgnoringHashCodes(
          'AutomaticKeepAlive:\n'
          '  state: _AutomaticKeepAliveState#00000(keeping subtree alive,\n'
          '    handles: 1 active client)\n',
        ),
      );
    });

    testWidgets(
      'start keep alive when wantKeepAlive changes to true',
      (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: DefaultTabController(
              length: 2,
              child: TabBarView(
                children: [
                  HookBuilder(builder: (context) {
                    final wantKeepAlive = useState(false);
                    useAutomaticKeepAlive(wantKeepAlive: wantKeepAlive.value);
                    useEffect(() {
                      Future.delayed(
                        const Duration(milliseconds: 250),
                        () => wantKeepAlive.value = true,
                      );
                      return null;
                    }, []);
                    return Container();
                  }),
                  Container(),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        final findKeepAlive = find.byType(AutomaticKeepAlive);
        final keepAlive = tester.element(findKeepAlive);

        expect(findKeepAlive, findsOneWidget);
        expect(
          keepAlive
              .toDiagnosticsNode(style: DiagnosticsTreeStyle.shallow)
              .toStringDeep(),
          equalsIgnoringHashCodes(
            'AutomaticKeepAlive:\n'
            '  state: _AutomaticKeepAliveState#00000(handles: no notifications\n'
            '    ever received)\n',
          ),
        );

        await tester.pump(const Duration(milliseconds: 250));

        expect(findKeepAlive, findsOneWidget);
        expect(
          keepAlive
              .toDiagnosticsNode(style: DiagnosticsTreeStyle.shallow)
              .toStringDeep(),
          equalsIgnoringHashCodes(
            'AutomaticKeepAlive:\n'
            '  state: _AutomaticKeepAliveState#00000(keeping subtree alive,\n'
            '    handles: 1 active client)\n',
          ),
        );
      },
    );
  });
}
