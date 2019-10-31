// ignore_for_file: public_member_api_docs

import 'package:flutter_hooks_gallery/star_wars/app_state.dart';
import 'package:flutter_hooks_gallery/star_wars/models.dart';

abstract class ReduxAction {}

class SetPlanetPageAction extends ReduxAction {
  final PlanetPageModel page;

  SetPlanetPageAction(this.page);
}

/// reducer that is used by [useReducer] to create the redux store
AppState reducer<S extends AppState, A extends ReduxAction>(S state, A action) {
  final b = state.toBuilder();
  if (action is SetPlanetPageAction) {
    b.planetPage.replace(action.page);
  }

  return b.build();
}
