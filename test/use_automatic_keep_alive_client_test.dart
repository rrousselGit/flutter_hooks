import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_hooks/src/framework.dart';
import 'package:flutter_test/flutter_test.dart';

class Leaf extends HookWidget {
  final Widget child;

  const Leaf({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    useAutomaticKeepAliveClient(wantKeepAlive: true);
    return child;
  }
}

List<Widget> generateList(Widget child) {
  return List<Widget>.generate(
    100,
    (int index) {
      final Widget result = Leaf(
        key: getKey(index),
        child: child,
      );
      return result;
    },
    growable: false,
  );
}

Key getKey(int index) => Key('$index');

void main() {
  testWidgets('AutomaticKeepAlive with ListView', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          addSemanticIndexes: false,
          scrollDirection: Axis.vertical,
          itemExtent: 12.3,
          // about 50 widgets visible
          cacheExtent: 0.0,
          children: generateList(const Placeholder()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(getKey(0)), findsOneWidget);
    expect(find.byKey(getKey(1)), findsOneWidget);
    expect(find.byKey(getKey(30)), findsOneWidget);
    expect(find.byKey(getKey(40)), findsOneWidget);
    expect(find.byKey(getKey(60), skipOffstage: false), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0.0, -300.0)); // down
    await tester.pump();
    expect(find.byKey(getKey(60), skipOffstage: false), findsOneWidget);
    expect(find.byKey(getKey(0), skipOffstage: false), findsOneWidget);
    expect(find.byKey(getKey(1), skipOffstage: false), findsOneWidget);
    expect(find.byKey(getKey(30), skipOffstage: false), findsOneWidget);
    expect(find.byKey(getKey(40), skipOffstage: false), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0.0, 300.0)); // top
    await tester.pump();
    expect(find.byKey(getKey(60), skipOffstage: false), findsOneWidget);
    expect(find.byKey(getKey(0), skipOffstage: false), findsOneWidget);
    expect(find.byKey(getKey(1), skipOffstage: false), findsOneWidget);
    expect(find.byKey(getKey(30), skipOffstage: false), findsOneWidget);
    expect(find.byKey(getKey(40), skipOffstage: false), findsOneWidget);
  });
}
