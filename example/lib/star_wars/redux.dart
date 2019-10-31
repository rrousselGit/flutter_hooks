import 'package:built_value/built_value.dart';
import 'package:flutter_hooks_gallery/star_wars/models.dart';

part 'redux.g.dart';

/// Actions base class
abstract class ReduxAction {}

/// Action to set the planet page
class SetPlanetPageAction extends ReduxAction {
  /// payload
  final PlanetPageModel page;

  /// constructor
  SetPlanetPageAction(this.page);
}

/// state of the redux store
abstract class AppState implements Built<AppState, AppStateBuilder> {
  /// current planet page
  PlanetPageModel get planetPage;

  AppState._();

  /// default factory
  factory AppState([void Function(AppStateBuilder) updates]) = _$AppState;
}

/// reducer that is used by useReducer to create the redux store
AppState reducer<S extends AppState, A extends ReduxAction>(S state, A action) {
  final b = state.toBuilder();
  if (action is SetPlanetPageAction) {
    b.planetPage.replace(action.page);
  }

  return b.build();
}
