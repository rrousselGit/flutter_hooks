import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression tests for https://github.com/rrousselGit/flutter_hooks/issues/215

class _Counter extends Hook<ValueNotifier<int>> {
  const _Counter({this.initial = 0, this.log, List<Object?>? keys})
      : super(keys: keys);

  final int initial;
  final List<String>? log;

  @override
  _CounterState createState() => _CounterState();
}

class _CounterState extends HookState<ValueNotifier<int>, _Counter> {
  @override
  void dispose() => hook.log?.add('dispose counter ${hook.initial}');

  @override
  ValueNotifier<int> build(BuildContext context) {
    final state = useState(hook.initial);
    useEffect(
      () => () => hook.log?.add('effect cleanup ${hook.initial}'),
      const [],
    );
    return state;
  }
}

class _Parent extends Hook<int> {
  const _Parent(this.log);

  final List<String> log;

  @override
  _ParentState createState() => _ParentState();
}

class _ParentState extends HookState<int, _Parent> {
  @override
  void dispose() => hook.log.add('dispose parent');

  @override
  int build(BuildContext context) {
    // Nested class hook which itself uses other hooks.
    return use(_Counter(initial: 10, log: hook.log)).value;
  }
}

void main() {
  testWidgets('class hooks can use other hooks', (tester) async {
    late ValueNotifier<int> a;
    late ValueNotifier<int> b;
    late ValueNotifier<String> sibling;

    Widget build() => HookBuilder(
          builder: (context) {
            a = use(const _Counter(initial: 1));
            sibling = useState('s');
            b = use(const _Counter(initial: 2));
            return const SizedBox();
          },
        );

    await tester.pumpWidget(build());

    expect(a.value, 1);
    expect(b.value, 2);
    expect(sibling.value, 's');

    final firstA = a;
    final firstB = b;
    a.value = 42;
    await tester.pump();

    expect(a, same(firstA));
    expect(b, same(firstB));
    expect(a.value, 42);
    expect(b.value, 2);

    await tester.pumpWidget(build());
    expect(a, same(firstA));
    expect(b, same(firstB));
  });

  testWidgets('nested hooks are disposed with their parent, children first',
      (tester) async {
    final log = <String>[];

    await tester.pumpWidget(
      HookBuilder(
        builder: (context) {
          use(_Parent(log));
          return const SizedBox();
        },
      ),
    );
    expect(log, isEmpty);

    await tester.pumpWidget(const SizedBox());

    expect(log, ['effect cleanup 10', 'dispose counter 10', 'dispose parent']);
  });

  testWidgets('changing keys of a hook recreates its nested hooks',
      (tester) async {
    final log = <String>[];
    late ValueNotifier<int> counter;
    late ValueNotifier<String> after;

    Widget build(int key) => HookBuilder(
          builder: (context) {
            counter = use(_Counter(initial: key, log: log, keys: [key]));
            after = useState('after');
            return const SizedBox();
          },
        );

    await tester.pumpWidget(build(1));
    final firstAfter = after;
    counter.value = 100;
    await tester.pump();

    await tester.pumpWidget(build(2));

    expect(counter.value, 2, reason: 'nested useState should be recreated');
    expect(after, same(firstAfter), reason: 'siblings should be preserved');
    expect(log, ['effect cleanup 1', 'dispose counter 1']);
  });

  testWidgets('deeply nested hooks keep their state', (tester) async {
    final log = <String>[];
    late int value;

    Widget build() => HookBuilder(
          builder: (context) {
            value = use(_Parent(log));
            return const SizedBox();
          },
        );

    await tester.pumpWidget(build());
    expect(value, 10);
    await tester.pumpWidget(build());
    expect(value, 10);
    expect(log, isEmpty);
  });
}
