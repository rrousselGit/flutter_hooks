// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers = (new Serializers().toBuilder()
      ..add(PlanetModel.serializer)
      ..add(PlanetPageModel.serializer)
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(PlanetModel)]),
          () => new ListBuilder<PlanetModel>()))
    .build();
Serializer<PlanetPageModel> _$planetPageModelSerializer =
    new _$PlanetPageModelSerializer();
Serializer<PlanetModel> _$planetModelSerializer = new _$PlanetModelSerializer();

class _$PlanetPageModelSerializer
    implements StructuredSerializer<PlanetPageModel> {
  @override
  final Iterable<Type> types = const [PlanetPageModel, _$PlanetPageModel];
  @override
  final String wireName = 'PlanetPageModel';

  @override
  Iterable<Object> serialize(Serializers serializers, PlanetPageModel object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'results',
      serializers.serialize(object.results,
          specifiedType:
              const FullType(BuiltList, const [const FullType(PlanetModel)])),
    ];
    if (object.next != null) {
      result
        ..add('next')
        ..add(serializers.serialize(object.next,
            specifiedType: const FullType(String)));
    }
    if (object.previous != null) {
      result
        ..add('previous')
        ..add(serializers.serialize(object.previous,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  PlanetPageModel deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new PlanetPageModelBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'next':
          result.next = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'previous':
          result.previous = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'results':
          result.results.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(PlanetModel)]))
              as BuiltList<dynamic>);
          break;
      }
    }

    return result.build();
  }
}

class _$PlanetModelSerializer implements StructuredSerializer<PlanetModel> {
  @override
  final Iterable<Type> types = const [PlanetModel, _$PlanetModel];
  @override
  final String wireName = 'PlanetModel';

  @override
  Iterable<Object> serialize(Serializers serializers, PlanetModel object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'name',
      serializers.serialize(object.name, specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  PlanetModel deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new PlanetModelBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$PlanetPageModel extends PlanetPageModel {
  @override
  final String next;
  @override
  final String previous;
  @override
  final BuiltList<PlanetModel> results;

  factory _$PlanetPageModel([void Function(PlanetPageModelBuilder) updates]) =>
      (new PlanetPageModelBuilder()..update(updates)).build();

  _$PlanetPageModel._({this.next, this.previous, this.results}) : super._() {
    if (results == null) {
      throw new BuiltValueNullFieldError('PlanetPageModel', 'results');
    }
  }

  @override
  PlanetPageModel rebuild(void Function(PlanetPageModelBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlanetPageModelBuilder toBuilder() =>
      new PlanetPageModelBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlanetPageModel &&
        next == other.next &&
        previous == other.previous &&
        results == other.results;
  }

  @override
  int get hashCode {
    return $jf(
        $jc($jc($jc(0, next.hashCode), previous.hashCode), results.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('PlanetPageModel')
          ..add('next', next)
          ..add('previous', previous)
          ..add('results', results))
        .toString();
  }
}

class PlanetPageModelBuilder
    implements Builder<PlanetPageModel, PlanetPageModelBuilder> {
  _$PlanetPageModel _$v;

  String _next;
  String get next => _$this._next;
  set next(String next) => _$this._next = next;

  String _previous;
  String get previous => _$this._previous;
  set previous(String previous) => _$this._previous = previous;

  ListBuilder<PlanetModel> _results;
  ListBuilder<PlanetModel> get results =>
      _$this._results ??= new ListBuilder<PlanetModel>();
  set results(ListBuilder<PlanetModel> results) => _$this._results = results;

  PlanetPageModelBuilder();

  PlanetPageModelBuilder get _$this {
    if (_$v != null) {
      _next = _$v.next;
      _previous = _$v.previous;
      _results = _$v.results?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlanetPageModel other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$PlanetPageModel;
  }

  @override
  void update(void Function(PlanetPageModelBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$PlanetPageModel build() {
    _$PlanetPageModel _$result;
    try {
      _$result = _$v ??
          new _$PlanetPageModel._(
              next: next, previous: previous, results: results.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'results';
        results.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'PlanetPageModel', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

class _$PlanetModel extends PlanetModel {
  @override
  final String name;

  factory _$PlanetModel([void Function(PlanetModelBuilder) updates]) =>
      (new PlanetModelBuilder()..update(updates)).build();

  _$PlanetModel._({this.name}) : super._() {
    if (name == null) {
      throw new BuiltValueNullFieldError('PlanetModel', 'name');
    }
  }

  @override
  PlanetModel rebuild(void Function(PlanetModelBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlanetModelBuilder toBuilder() => new PlanetModelBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlanetModel && name == other.name;
  }

  @override
  int get hashCode {
    return $jf($jc(0, name.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('PlanetModel')..add('name', name))
        .toString();
  }
}

class PlanetModelBuilder implements Builder<PlanetModel, PlanetModelBuilder> {
  _$PlanetModel _$v;

  String _name;
  String get name => _$this._name;
  set name(String name) => _$this._name = name;

  PlanetModelBuilder();

  PlanetModelBuilder get _$this {
    if (_$v != null) {
      _name = _$v.name;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlanetModel other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$PlanetModel;
  }

  @override
  void update(void Function(PlanetModelBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$PlanetModel build() {
    final _$result = _$v ?? new _$PlanetModel._(name: name);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
