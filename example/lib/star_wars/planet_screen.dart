import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_hooks_gallery/star_wars/redux.dart';
import 'package:flutter_hooks_gallery/star_wars/star_wars_api.dart';
import 'package:provider/provider.dart';

/// This handler will take care of async api interactions
/// and updating the store afterwards.
class _PlanetHandler {
  _PlanetHandler(this._store, this._starWarsApi);

  final Store<AppState, ReduxAction> _store;
  final StarWarsApi _starWarsApi;

  /// This will load all planets and will dispatch all necessary actions
  /// on the redux store.
  Future<void> fetchAndDispatch([String url]) async {
    _store.dispatch(FetchPlanetPageActionStart());
    try {
      final page = await _starWarsApi.getPlanets(url);
      _store.dispatch(FetchPlanetPageActionSuccess(page));
    } catch (e) {
      _store.dispatch(FetchPlanetPageActionError('Error loading Planets'));
    }
  }
}

/// This example will load, show and let you navigate through all star wars
/// planets.
///
/// It will demonstrate on how to use [Provider] and [useReducer]
class PlanetScreen extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final api = useMemoized(() => StarWarsApi());

    final store = useReducer(
      reducer,
      initialState: AppState(),
    );

    final planetHandler = useMemoized(
      () {
        /// Create planet handler and load the first page.
        /// The first page will only be loaded once, after the handler was created
        return _PlanetHandler(store, api)..fetchAndDispatch();
        return handler;
      },
      [store, api],
    );

    return MultiProvider(
      providers: [
        Provider.value(value: planetHandler),
        Provider.value(value: store.state),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Star Wars Planets',
          ),
        ),
        body: const _PlanetScreenBody(),
      ),
    );
  }
}

class _PlanetScreenBody extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final index = useMemoized(() {
      if (state.isFetchingPlanets) {
        return 0;
      }

      if (state.planetPage.results.isEmpty) {
        return 1;
      }

      if (state.errorFetchingPlanets != null) {
        return 2;
      }

      return 3;
    }, [
      state.isFetchingPlanets,
      state.planetPage.results.isEmpty,
      state.errorFetchingPlanets
    ]);

    return IndexedStack(
      children: <Widget>[
        Center(
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
        Container(
          alignment: Alignment.center,
          child: const Text('No planets found'),
        ),
        _Error(
          errorMsg: state.errorFetchingPlanets,
        ),
        _PlanetList(),
      ],
      index: index,
    );
  }
}

class _Error extends StatelessWidget {
  final String errorMsg;

  const _Error({Key key, this.errorMsg}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final handler = Provider.of<_PlanetHandler>(context);
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (errorMsg != null) Text(errorMsg),
          RaisedButton(
            color: Colors.redAccent,
            child: const Text('Try again'),
            onPressed: () async {
              await handler.fetchAndDispatch();
            },
          ),
        ],
      ),
    );
  }
}

class _LoadPageButton extends HookWidget {
  _LoadPageButton({this.next = true}) : assert(next != null);

  final bool next;

  @override
  Widget build(BuildContext context) {
    final handler = Provider.of<_PlanetHandler>(context);
    final state = Provider.of<AppState>(context);
    return RaisedButton(
      child: next ? const Text('Next Page') : const Text('Prev Page'),
      onPressed: () async {
        final url = next ? state.planetPage.next : state.planetPage.previous;
        await handler.fetchAndDispatch(url);
      },
    );
  }
}

class _PlanetList extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return ListView.builder(
      itemCount: 1 + state.planetPage.results.length,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _PlanetListHeader();
        }

        final planet = state.planetPage.results[index - 1];
        return ListTile(
          title: Text(planet.name),
        );
      },
    );
  }
}

class _PlanetListHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return HookBuilder(builder: (context) {
      final buttonAlignment = useMemoized(
        () {
          if (state.planetPage.previous == null) {
            return MainAxisAlignment.end;
          }
          if (state.planetPage.next == null) {
            return MainAxisAlignment.start;
          }
          return MainAxisAlignment.spaceBetween;
        },
        [state],
      );

      return Row(
        mainAxisAlignment: buttonAlignment,
        children: <Widget>[
          if (state.planetPage.previous != null) _LoadPageButton(next: false),
          if (state.planetPage.next != null) _LoadPageButton(next: true)
        ],
      );
    });
  }
}
