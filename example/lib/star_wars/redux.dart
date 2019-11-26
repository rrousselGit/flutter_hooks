import 'package:built_value/built_value.dart';
import 'package:flutter_hooks_gallery/star_wars/models.dart';

part 'redux.g.dart';

/// Actions base class
abstract class ReduxAction {}

/// Action that updates state to show that we are loading planets
class FetchPlanetPageActionStart extends ReduxAction {}

/// Action that updates state to show that we are loading planets
class FetchPlanetPageActionError extends ReduxAction {
  /// Message that should be displayed in the UI
  final String errorMsg;

  /// constructor
  FetchPlanetPageActionError(this.errorMsg);
}

/// Action to set the planet page
class FetchPlanetPageActionSuccess extends ReduxAction {
  /// payload
  final PlanetPageModel page;

  /// constructor
  FetchPlanetPageActionSuccess(this.page);
}

/// state of the redux store
abstract class AppState implements Built<AppState, AppStateBuilder> {
  AppState._();

  /// default factory
  factory AppState([void Function(AppStateBuilder) updates]) =>
      _$AppState((u) => u
        ..isFetchingPlanets = false
        ..update(updates));

  /// are we currently loading planets
  bool get isFetchingPlanets;

  /// will be set if loading planets failed. This is an error message
  @nullable
  String get errorFetchingPlanets;

  /// current planet page
  PlanetPageModel get planetPage;
}

/// reducer that is used by useReducer to create the redux store
AppState reducer<S extends AppState, A extends ReduxAction>(S state, A action) {
  final b = state.toBuilder();
  if (action is FetchPlanetPageActionStart) {
    b
      ..isFetchingPlanets = true
      ..planetPage = PlanetPageModelBuilder()
      ..errorFetchingPlanets = null;
  }

  if (action is FetchPlanetPageActionError) {
    b
      ..isFetchingPlanets = false
      ..errorFetchingPlanets = action.errorMsg;
  }

  if (action is FetchPlanetPageActionSuccess) {
    b
      ..isFetchingPlanets = false
      ..planetPage.replace(action.page);
  }

  return b.build();
}
