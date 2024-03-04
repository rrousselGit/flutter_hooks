part of 'hooks.dart';

/// Creates a general purpose hook on a [ChangeNotifier] subclass that will be
/// disposed automatically.
///
/// For example, this hook:
/// ```dart
/// useTextEditingController(text: 'Hello');
/// ```
/// which is actually implemented by using `useChangeNotifier`:
/// ```dart
/// useChangeNotifier(() => TextEditingController(text: 'Hello'));
/// ```
T useChangeNotifier<T extends ChangeNotifier>(
  T Function() factory, [
  String? label,
  List<Object?>? keys,
]) {
  return useDispose(
    factory,
    (entity) => entity.dispose(),
    label,
    keys,
  );
}
