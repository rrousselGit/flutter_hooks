import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_hooks_gallery/star_wars/app_state.dart';
import 'package:flutter_hooks_gallery/star_wars/redux.dart';
import 'package:flutter_hooks_gallery/star_wars/star_wars_api.dart';
import 'package:provider/provider.dart';

typedef FetchAndDispatchPlanets = Future<void> Function(String);

/// return the redux store created by [useReducer}
/// We use [Provider] to retrieve the redux store.
Store<AppState, ReduxAction> useAppStore() {
  final context = useContext();
  return Provider.of<Store<AppState, ReduxAction>>(context);
}

/// return [AppState] hold by redux store.
/// We use [Provider] to retrieve the [AppState].
/// This will also rebuild whenever the [AppState] has been changed
AppState useAppState() {
  final context = useContext();
  return Provider.of<AppState>(context);
}

/// return star wars api.
/// We use [Provider] to retrieve the [StarWarsApi].
StarWarsApi useStarWarsApi() {
  final context = useContext();
  return Provider.of<StarWarsApi>(context);
}

/// "middleware" to load data and update state
/// We use [Provider] to retrieve the [FetchAndDispatchPlanets] "middleware".
FetchAndDispatchPlanets useFetchAndDispatchPlanets() {
  final context = useContext();
  return Provider.of<FetchAndDispatchPlanets>(context);
}
