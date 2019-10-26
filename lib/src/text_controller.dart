part of 'hooks.dart';

class _TextEditingControllerHookCreator {
  const _TextEditingControllerHookCreator();

  /// Creates a [TextEditingController] that will be disposed automatically.
  ///
  /// The [text] parameter can be used to set the initial value of the
  /// controller.
  TextEditingController call({String text, List<Object> keys}) {
    return Hook.use(_TextEditingControllerHook(text, null, keys));
  }

  /// Creates a [TextEditingController] from the initial [value] that will
  /// be disposed automatically.
  TextEditingController fromValue(TextEditingValue value, [List<Object> keys]) {
    return Hook.use(_TextEditingControllerHook(null, value, keys));
  }
}

/// Functions to create a text editing controller, either via an initial
/// text or an initial [TextEditingValue].
///
/// To use a [TextEditingController] with an optional initial text, use
/// [_TextEditingControllerHookCreator.call]:
/// ```dart
/// final controller = useTextEditingController(text: 'initial text');
/// ```
///
/// To use a [TextEditingController] with an optional inital value, use
/// [_TextEditingControllerHookCreator.fromValue]:
/// ```dart
/// final controller = useTextEditingController
///   .fromValue(TextEditingValue.empty);
/// ```
const useTextEditingController = _TextEditingControllerHookCreator();

class _TextEditingControllerHook extends Hook<TextEditingController> {
  final String initialText;
  final TextEditingValue initialValue;

  _TextEditingControllerHook(this.initialText, this.initialValue,
      [List<Object> keys])
      : assert(
          initialText == null || initialValue == null,
          "initialText and intialValue can't both be set on a call to "
          'useTextEditingController!',
        ),
        super(keys: keys);

  @override
  HookState<TextEditingController, _TextEditingControllerHook> createState() {
    return _TextEditingControllerHookState();
  }
}

class _TextEditingControllerHookState
    extends HookState<TextEditingController, _TextEditingControllerHook> {
  TextEditingController _controller;

  TextEditingController _constructController() {
    if (hook.initialText != null) {
      return TextEditingController(text: hook.initialText);
    } else if (hook.initialValue != null) {
      return TextEditingController.fromValue(hook.initialValue);
    } else {
      return TextEditingController();
    }
  }

  @override
  TextEditingController build(BuildContext context) {
    return _controller ??= _constructController();
  }

  @override
  void dispose() => _controller?.dispose();
}
