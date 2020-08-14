import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('register property', (tester) async {
    RestorationBucket bucket;

    Future pump() {
      return tester.pumpWidget(RootRestorationScope(
        restorationId: 'root',
        child: HookRestorationScope(
          restorationId: 'hook',
          child: HookBuilder(
            builder: (context) {
              useRestorationProperty('prop', RestorableInt(0));
              bucket = RestorationScope.of(context);
              return Container();
            },
          ),
        ),
      ));
    }

    await pump();

    expect(bucket.read<int>('prop'), equals(0));
  });

  testWidgets('change restorationId', (tester) async {
    ValueNotifier<String> restorationId;
    RestorationBucket bucket;

    Future pump() {
      return tester.pumpWidget(RootRestorationScope(
        restorationId: 'root',
        child: HookRestorationScope(
          restorationId: 'hook',
          child: HookBuilder(
            builder: (context) {
              restorationId = useState('prop');
              useRestorationProperty(restorationId.value, RestorableInt(0));
              bucket = RestorationScope.of(context);
              return Container();
            },
          ),
        ),
      ));
    }

    await pump();

    expect(bucket.read<int>('prop'), equals(0));

    restorationId.value = 'renamedProp';

    await tester.pump();

    expect(bucket.contains('prop'), isFalse);
    expect(bucket.read<int>('renamedProp'), equals(0));
  });

  testWidgets('restore property', (tester) async {
    RestorableInt prop;

    Future pump() {
      return tester.pumpWidget(RootRestorationScope(
        restorationId: 'root',
        child: HookRestorationScope(
          restorationId: 'hook',
          child: HookBuilder(
            builder: (context) {
              prop = useRestorationProperty('prop', RestorableInt(0));
              return Container();
            },
          ),
        ),
      ));
    }

    await pump();

    final restorationData = await tester.getRestorationData();

    prop.value = 1;

    await tester.restoreFrom(restorationData);

    expect(prop.value, equals(0));
  });

  testWidgets('dispose property', (tester) async {
    _DisposeTestProperty prop;
    ValueNotifier<bool> propIsActive;

    Future pump() {
      return tester.pumpWidget(HookBuilder(builder: (_) {
        propIsActive = useState(true);
        return !propIsActive.value
            ? Container()
            : RootRestorationScope(
                restorationId: 'root',
                child: HookRestorationScope(
                  restorationId: 'hook',
                  child: HookBuilder(
                    builder: (_) {
                      prop = useRestorationProperty(
                        'prop',
                        _DisposeTestProperty(),
                      );
                      return Container();
                    },
                  ),
                ),
              );
      }));
    }

    await pump();

    prop.addListener(() {});

    propIsActive.value = false;

    await tester.pumpAndSettle();

    expect(prop.isDisposed, isTrue);
  });
}

class _DisposeTestProperty extends RestorableInt {
  _DisposeTestProperty() : super(0);

  bool isDisposed = false;

  @override
  void dispose() {
    isDisposed = true;
    super.dispose();
  }
}
