part of 'hooks.dart';

/// Creates an [TextEditingController] that will be disposed automatically.
///
/// The optional [initialText] parameter can be used to set the initial
/// [TextEditingController.text]. Similarly, [initialValue] can be used to set
/// the initial [TextEditingController.value]. It is invalid to set both
/// [initialText] and [initialValue].
/// When this hook is re-used with different values of [initialText] or
/// [initialValue], the underlying [TextEditingController] will _not_ be
/// updated. Set values on [TextEditingController.text] or
/// [TextEditingController.value] directly to change the text or selection,
/// respectively.
TextEditingController useTextEditingController(
    {String initialText, TextEditingValue initialValue, List<Object> keys}) {
  return Hook.use(_TextEditingControllerHook(initialText, initialValue, keys));
}

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
