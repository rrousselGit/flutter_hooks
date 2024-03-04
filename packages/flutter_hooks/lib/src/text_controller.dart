part of 'hooks.dart';

class _TextEditingControllerHookCreator {
  const _TextEditingControllerHookCreator();

  /// Creates a [TextEditingController] that will be disposed automatically.
  ///
  /// The [text] parameter can be used to set the initial value of the
  /// controller.
  TextEditingController call({String? text, List<Object?>? keys}) {
    return useChangeNotifier(
      () => TextEditingController(text: text),
      'useTextEditingController',
       keys,
    );
  }

  /// Creates a [TextEditingController] from the initial [value] that will
  /// be disposed automatically.
  TextEditingController fromValue(
    TextEditingValue value, [
    List<Object?>? keys,
  ]) {
    return useChangeNotifier(
      () => TextEditingController.fromValue(value),
      'useTextEditingController',
      keys,
    );
  }
}

/// Creates a [TextEditingController], either via an initial text or an initial
/// [TextEditingValue].
///
/// To use a [TextEditingController] with an optional initial text, use:
/// ```dart
/// final controller = useTextEditingController(text: 'initial text');
/// ```
///
/// To use a [TextEditingController] with an optional initial value, use:
/// ```dart
/// final controller = useTextEditingController
///   .fromValue(TextEditingValue.empty);
/// ```
///
/// Changing the text or initial value after the widget has been built has no
/// effect whatsoever. To update the value in a callback, for instance after a
/// button was pressed, use the [TextEditingController.text] or
/// [TextEditingController.value] setters. To have the [TextEditingController]
/// reflect changing values, you can use [useEffect]. This example will update
/// the [TextEditingController.text] whenever a provided [ValueListenable]
/// changes:
/// ```dart
/// final controller = useTextEditingController();
/// final update = useValueListenable(myTextControllerUpdates);
///
/// useEffect(() {
///   controller.text = update;
/// }, [update]);
/// ```
///
/// See also:
/// - [TextEditingController], which this hook creates.
const useTextEditingController = _TextEditingControllerHookCreator();
