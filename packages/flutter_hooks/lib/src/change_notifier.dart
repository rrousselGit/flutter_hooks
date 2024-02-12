part of 'hooks.dart';

/// Creates a general purpose hook on a [ChangeNotifier] subclass that will be
/// disposed automatically.
///
/// For example, these are equivalent:
/// ```dart
/// useTextEditingController(text: 'Hello');
/// ```
/// And:
/// ```dart
/// useDisposable(() => TextEditingController(text: 'Hello'));
/// ```
/// This is very useful if you can't find a "common controller" class in Flutter
/// which has not a hook implementation, for example `CupertinoTabController`:
/// ```dart
/// useDisposable(() => CupertinoTabController());
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
