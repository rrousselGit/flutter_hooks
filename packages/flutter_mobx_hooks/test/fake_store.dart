import 'package:mobx/mobx.dart';

// Include generated file
part 'fake_store.g.dart';

// This is the class used by rest of your codebase
class Counter = _Counter with _$Counter;

// The store-class
abstract class _Counter with Store {
  @observable
  int value = 0;

  @observable
  int value2 = 0;

  @action
  void increment() {
    value++;
  }

  @action
  void increment2() {
    value2++;
  }
}
