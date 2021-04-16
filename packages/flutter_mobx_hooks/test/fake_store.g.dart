// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fake_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$Counter on _Counter, Store {
  final _$valueAtom = Atom(name: '_Counter.value');
  final _$value2Atom = Atom(name: '_Counter.value2');

  @override
  int get value {
    _$valueAtom.reportRead();
    return super.value;
  }

  @override
  set value(int value) {
    _$valueAtom.reportWrite(value, super.value, () {
      super.value = value;
    });
  }

  @override
  int get value2 {
    _$value2Atom.reportRead();
    return super.value2;
  }

  @override
  set value2(int value) {
    _$value2Atom.reportWrite(value, super.value, () {
      super.value2 = value;
    });
  }

  final _$_CounterActionController = ActionController(name: '_Counter');

  @override
  void increment() {
    final _$actionInfo =
        _$_CounterActionController.startAction(name: '_Counter.increment');
    try {
      return super.increment();
    } finally {
      _$_CounterActionController.endAction(_$actionInfo);
    }
  }

  @override
  void increment2() {
    final _$actionInfo =
    _$_CounterActionController.startAction(name: '_Counter.increment2');
    try {
      return super.increment2();
    } finally {
      _$_CounterActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
value: ${value}
value2: ${value2}
    ''';
  }
}
