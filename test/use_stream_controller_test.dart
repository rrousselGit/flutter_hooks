import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  group('useStreamController', () {
    testWidgets('basics', (tester) async {
      StreamController<int> controller;

      await tester.pumpWidget(HookBuilder(builder: (context) {
        controller = context.useStreamController();
        return Container();
      }));

      expect(controller, isNot(isInstanceOf<SynchronousStreamController>()));
      expect(controller.onListen, isNull);
      expect(controller.onCancel, isNull);
      expect(() => controller.onPause, throwsUnsupportedError);
      expect(() => controller.onResume, throwsUnsupportedError);

      final previousController = controller;
      final onListen = () {};
      final onCancel = () {};
      await tester.pumpWidget(HookBuilder(builder: (context) {
        controller = context.useStreamController(
          sync: true,
          onCancel: onCancel,
          onListen: onListen,
        );
        return Container();
      }));

      expect(controller, previousController);
      expect(controller, isNot(isInstanceOf<SynchronousStreamController>()));
      expect(controller.onListen, onListen);
      expect(controller.onCancel, onCancel);
      expect(() => controller.onPause, throwsUnsupportedError);
      expect(() => controller.onResume, throwsUnsupportedError);

      await tester.pumpWidget(Container());

      expect(controller.isClosed, true);
    });
    testWidgets('sync', (tester) async {
      StreamController<int> controller;

      await tester.pumpWidget(HookBuilder(builder: (context) {
        controller = context.useStreamController(sync: true);
        return Container();
      }));

      expect(controller, isInstanceOf<SynchronousStreamController>());
      expect(controller.onListen, isNull);
      expect(controller.onCancel, isNull);
      expect(() => controller.onPause, throwsUnsupportedError);
      expect(() => controller.onResume, throwsUnsupportedError);

      final previousController = controller;
      final onListen = () {};
      final onCancel = () {};
      await tester.pumpWidget(HookBuilder(builder: (context) {
        controller = context.useStreamController(
          onCancel: onCancel,
          onListen: onListen,
        );
        return Container();
      }));

      expect(controller, previousController);
      expect(controller, isInstanceOf<SynchronousStreamController>());
      expect(controller.onListen, onListen);
      expect(controller.onCancel, onCancel);
      expect(() => controller.onPause, throwsUnsupportedError);
      expect(() => controller.onResume, throwsUnsupportedError);

      await tester.pumpWidget(Container());

      expect(controller.isClosed, true);
    });
  });
}
