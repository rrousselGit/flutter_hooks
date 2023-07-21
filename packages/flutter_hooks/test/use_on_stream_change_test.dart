import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    final stream = Stream.value(42);

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useOnStreamChange(stream);
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
        " │ useOnStreamChange: Instance of '_ControllerSubscription<int>'\n"
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  testWidgets('calls onData when data arrives', (tester) async {
    const data = 42;
    final stream = Stream<int>.value(data);

    late int value;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useOnStreamChange<int>(
          stream,
          onData: (data) {
            value = data;
          },
        );
        return const SizedBox();
      }),
    );

    expect(value, data);
  });

  testWidgets('calls onError when error occurs', (tester) async {
    final error = Exception();
    final stream = Stream<int>.error(error);

    late Object receivedError;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useOnStreamChange<int>(
          stream,
          onError: (error, stackTrace) {
            receivedError = error;
          },
        );
        return const SizedBox();
      }),
    );

    expect(receivedError, same(error));
  });

  testWidgets('calls onDone when stream is closed', (tester) async {
    final streamController = StreamController<int>.broadcast();

    var onDoneCalled = false;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useOnStreamChange<int>(
          streamController.stream,
          onDone: () {
            onDoneCalled = true;
          },
        );
        return const SizedBox();
      }),
    );

    await streamController.close();

    expect(onDoneCalled, isTrue);
  });

  testWidgets(
    'cancels subscription when cancelOnError is true and error occurrs',
    (tester) => tester.runAsync(() async {
      final streamController = StreamController<int>();

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          useOnStreamChange<int>(
            streamController.stream,
            // onError needs to be set to prevent unhandled errors from propagating.
            onError: (error, stackTrace) {},
            cancelOnError: true,
          );
          return const SizedBox();
        }),
      );

      expect(streamController.hasListener, isTrue);

      streamController.addError(Exception());

      await tester.pump();

      expect(streamController.hasListener, isFalse);

      await streamController.close();
    }),
  );

  testWidgets(
    'listens new stream when stream is changed',
    (tester) => tester.runAsync(() async {
      final streamController1 = StreamController<int>();
      final streamController2 = StreamController<int>();

      late StreamSubscription<int> subscription1;
      late StreamSubscription<int> subscription2;

      await tester.pumpWidget(
        HookBuilder(
          key: const Key('hook_builder'),
          builder: (context) {
            subscription1 = useOnStreamChange<int>(streamController1.stream)!;
            return const SizedBox();
          },
        ),
      );

      expect(streamController1.hasListener, isTrue);
      expect(streamController2.hasListener, isFalse);

      await tester.pumpWidget(
        HookBuilder(
          key: const Key('hook_builder'),
          builder: (context) {
            subscription2 = useOnStreamChange<int>(streamController2.stream)!;
            return const SizedBox();
          },
        ),
      );

      expect(streamController1.hasListener, isFalse);
      expect(streamController2.hasListener, isTrue);

      expect(subscription1, isNot(same(subscription2)));

      await streamController1.close();
      await streamController2.close();
    }),
  );

  testWidgets(
    'resubscribes stream when cancelOnError changed',
    (tester) => tester.runAsync(() async {
      var listenCount = 0;
      var cancelCount = 0;

      final streamController = StreamController<int>.broadcast(
        onListen: () => listenCount++,
        onCancel: () => cancelCount++,
      );
      final stream = streamController.stream;

      await tester.pumpWidget(
        HookBuilder(
          key: const Key('hook'),
          builder: (context) {
            useOnStreamChange<int>(
              stream,
              cancelOnError: false,
            );
            return const SizedBox();
          },
        ),
      );

      expect(listenCount, 1);
      expect(cancelCount, isZero);

      await tester.pumpWidget(
        HookBuilder(
          key: const Key('hook'),
          builder: (context) {
            useOnStreamChange<int>(
              stream,
              cancelOnError: true,
            );
            return const SizedBox();
          },
        ),
      );

      expect(listenCount, 2);
      expect(cancelCount, 1);

      await streamController.close();
    }),
  );

  testWidgets(
    'stop listening when cancel is called on StreamSubscription',
    (tester) => tester.runAsync(() async {
      final streamController = StreamController<int>();

      late StreamSubscription<int> subscription;

      await tester.pumpWidget(
        HookBuilder(
          key: const Key('hook_builder'),
          builder: (context) {
            subscription = useOnStreamChange<int>(streamController.stream)!;
            return const SizedBox();
          },
        ),
      );

      await subscription.cancel();

      expect(streamController.hasListener, isFalse);

      await streamController.close();
    }),
  );

  testWidgets('returns null when stream is null', (tester) async {
    StreamSubscription<int>? subscription;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        subscription = useOnStreamChange<int>(null);
        return const SizedBox();
      }),
    );

    expect(subscription, isNull);
  });

  testWidgets(
    'unsubscribes when stream changed to null',
    (tester) => tester.runAsync(() async {
      final streamController = StreamController<int>();

      StreamSubscription<int>? subscription;

      await tester.pumpWidget(
        HookBuilder(
          key: const Key('hook_builder'),
          builder: (context) {
            subscription = useOnStreamChange<int>(streamController.stream);
            return const SizedBox();
          },
        ),
      );

      expect(streamController.hasListener, isTrue);
      expect(subscription, isNotNull);

      await tester.pumpWidget(
        HookBuilder(
          key: const Key('hook_builder'),
          builder: (context) {
            subscription = useOnStreamChange<int>(null);
            return const SizedBox();
          },
        ),
      );

      expect(streamController.hasListener, isFalse);
      expect(subscription, isNotNull);

      await streamController.close();
    }),
  );
}
