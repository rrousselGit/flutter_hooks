import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets(
    'debugFillProperties',
    (tester) async {
      final stream = Stream.value(42);

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          useStreamListener(stream);
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
          ' │ useStreamListener\n'
          ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
        ),
      );
    },
  );

  testWidgets(
    'calls onData when data arrives',
    (tester) async {
      const data = 42;
      final stream = Stream<int>.value(data);

      late int value;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          useStreamListener<int>(
            stream,
            onData: (data) {
              value = data;
            },
          );
          return const SizedBox();
        }),
      );

      expect(value, data);
    },
  );

  testWidgets(
    'calls onError when error occurs',
    (tester) async {
      final error = Exception();
      final stream = Stream<int>.error(error);

      late Object receivedError;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          useStreamListener<int>(
            stream,
            onError: (error, stackTrace) {
              receivedError = error;
            },
          );
          return const SizedBox();
        }),
      );

      expect(receivedError, same(error));
    },
  );

  testWidgets(
    'calls onDone when stream is closed',
    (tester) async {
      final streamController = StreamController<int>.broadcast();

      var onDoneCalled = false;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          useStreamListener<int>(
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
    },
  );

  testWidgets(
    'cancels subscription when cancelOnError is true and error occurrs',
    (tester) async {
      // ignore: close_sinks
      final streamController = StreamController<int>();

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          useStreamListener<int>(
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
    },
  );

  testWidgets(
    'listens new stream when stream is changed',
    (tester) async {
      const value1 = 42;
      const value2 = 43;

      final stream1 = Stream<int>.value(value1);
      final stream2 = Stream<int>.value(value2);

      late int receivedValue;

      await tester.pumpWidget(
        HookBuilder(
          key: const Key('hook_builder'),
          builder: (context) {
            useStreamListener<int>(
              stream1,
              onData: (data) => receivedValue = data,
            );
            return const SizedBox();
          },
        ),
      );

      expect(receivedValue, value1);

      // Listens to the stream2
      await tester.pumpWidget(
        HookBuilder(
          key: const Key('hook_builder'),
          builder: (context) {
            useStreamListener<int>(
              stream2,
              onData: (data) => receivedValue = data,
            );
            return const SizedBox();
          },
        ),
      );

      expect(receivedValue, value2);
    },
  );
}
