// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redux.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AppState extends AppState {
  @override
  final PlanetPageModel planetPage;

  factory _$AppState([void Function(AppStateBuilder) updates]) =>
      (new AppStateBuilder()..update(updates)).build();

  _$AppState._({this.planetPage}) : super._() {
    if (planetPage == null) {
      throw new BuiltValueNullFieldError('AppState', 'planetPage');
    }
  }

  @override
  AppState rebuild(void Function(AppStateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AppStateBuilder toBuilder() => new AppStateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AppState && planetPage == other.planetPage;
  }

  @override
  int get hashCode {
    return $jf($jc(0, planetPage.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('AppState')
          ..add('planetPage', planetPage))
        .toString();
  }
}

class AppStateBuilder implements Builder<AppState, AppStateBuilder> {
  _$AppState _$v;

  PlanetPageModelBuilder _planetPage;
  PlanetPageModelBuilder get planetPage =>
      _$this._planetPage ??= new PlanetPageModelBuilder();
  set planetPage(PlanetPageModelBuilder planetPage) =>
      _$this._planetPage = planetPage;

  AppStateBuilder();

  AppStateBuilder get _$this {
    if (_$v != null) {
      _planetPage = _$v.planetPage?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AppState other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$AppState;
  }

  @override
  void update(void Function(AppStateBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$AppState build() {
    _$AppState _$result;
    try {
      _$result = _$v ?? new _$AppState._(planetPage: planetPage.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'planetPage';
        planetPage.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'AppState', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
