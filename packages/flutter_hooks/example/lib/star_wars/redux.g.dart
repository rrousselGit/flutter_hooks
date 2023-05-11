// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redux.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AppState extends AppState {
  @override
  final bool isFetchingPlanets;
  @override
  final String? errorFetchingPlanets;
  @override
  final PlanetPageModel planetPage;

  factory _$AppState([void Function(AppStateBuilder)? updates]) =>
      (new AppStateBuilder()..update(updates))._build();

  _$AppState._(
      {required this.isFetchingPlanets,
      this.errorFetchingPlanets,
      required this.planetPage})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        isFetchingPlanets, r'AppState', 'isFetchingPlanets');
    BuiltValueNullFieldError.checkNotNull(
        planetPage, r'AppState', 'planetPage');
  }

  @override
  AppState rebuild(void Function(AppStateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AppStateBuilder toBuilder() => new AppStateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AppState &&
        isFetchingPlanets == other.isFetchingPlanets &&
        errorFetchingPlanets == other.errorFetchingPlanets &&
        planetPage == other.planetPage;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, isFetchingPlanets.hashCode);
    _$hash = $jc(_$hash, errorFetchingPlanets.hashCode);
    _$hash = $jc(_$hash, planetPage.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AppState')
          ..add('isFetchingPlanets', isFetchingPlanets)
          ..add('errorFetchingPlanets', errorFetchingPlanets)
          ..add('planetPage', planetPage))
        .toString();
  }
}

class AppStateBuilder implements Builder<AppState, AppStateBuilder> {
  _$AppState? _$v;

  bool? _isFetchingPlanets;
  bool? get isFetchingPlanets => _$this._isFetchingPlanets;
  set isFetchingPlanets(bool? isFetchingPlanets) =>
      _$this._isFetchingPlanets = isFetchingPlanets;

  String? _errorFetchingPlanets;
  String? get errorFetchingPlanets => _$this._errorFetchingPlanets;
  set errorFetchingPlanets(String? errorFetchingPlanets) =>
      _$this._errorFetchingPlanets = errorFetchingPlanets;

  PlanetPageModelBuilder? _planetPage;
  PlanetPageModelBuilder get planetPage =>
      _$this._planetPage ??= new PlanetPageModelBuilder();
  set planetPage(PlanetPageModelBuilder? planetPage) =>
      _$this._planetPage = planetPage;

  AppStateBuilder();

  AppStateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _isFetchingPlanets = $v.isFetchingPlanets;
      _errorFetchingPlanets = $v.errorFetchingPlanets;
      _planetPage = $v.planetPage.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AppState other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$AppState;
  }

  @override
  void update(void Function(AppStateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AppState build() => _build();

  _$AppState _build() {
    _$AppState _$result;
    try {
      _$result = _$v ??
          new _$AppState._(
              isFetchingPlanets: BuiltValueNullFieldError.checkNotNull(
                  isFetchingPlanets, r'AppState', 'isFetchingPlanets'),
              errorFetchingPlanets: errorFetchingPlanets,
              planetPage: planetPage.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'planetPage';
        planetPage.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'AppState', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
