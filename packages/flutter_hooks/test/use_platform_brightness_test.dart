import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  group('usePlatformBrightness', () {
    testWidgets('returns initial value and rebuild widgets on change',
        (tester) async {
      tester.binding.window.platformBrightnessTestValue = Brightness.light;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            final brightness = usePlatformBrightness();
            return Text('$brightness', textDirection: TextDirection.ltr);
          },
        ),
      );

      expect(find.text('Brightness.light'), findsOneWidget);

      tester.binding.window.platformBrightnessTestValue = Brightness.dark;
      await tester.pump();

      expect(find.text('Brightness.dark'), findsOneWidget);
    });
  });

  group('useOnPlatformBrightnessChange', () {
    testWidgets(
        'sends previous and new value on change, without rebuilding widgets',
        (tester) async {
      tester.binding.window.platformBrightnessTestValue = Brightness.light;
      var buildCount = 0;
      final listener = PlatformBrightnessListener();

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            buildCount++;
            useOnPlatformBrightnessChange(listener);
            return Container();
          },
        ),
      );

      expect(buildCount, 1);
      verifyZeroInteractions(listener);

      tester.binding.window.platformBrightnessTestValue = Brightness.dark;
      await tester.pump();

      expect(buildCount, 1);
      verify(listener(Brightness.light, Brightness.dark));
      verifyNoMoreInteractions(listener);

      tester.binding.window.platformBrightnessTestValue = Brightness.light;
      await tester.pump();

      expect(buildCount, 1);
      verify(listener(Brightness.dark, Brightness.light));
      verifyNoMoreInteractions(listener);
    });
  });
}

class PlatformBrightnessListener extends Mock {
  void call(Brightness previous, Brightness current);
}
