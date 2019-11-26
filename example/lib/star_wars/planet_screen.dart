import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_hooks_gallery/star_wars/redux.dart';
import 'package:flutter_hooks_gallery/star_wars/star_wars_api.dart';
import 'package:provider/provider.dart';

/// This handler will take care of async api interactions
/// and updating the store afterwards.
class _PlanetHandler {
  /// constructor
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
      () => _PlanetHandler(store, api),
      [store, api],
    );

    /// load the first planet page but only once
    useEffect(
      () {
        planetHandler.fetchAndDispatch(null);
        return () {};
      },
      [planetHandler],
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
        body: _PlanetScreenBody(),
      ),
    );
  }
}

class _PlanetScreenBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (null != state.errorFetchingPlanets) {
          return _Error(
            errorMsg: state.errorFetchingPlanets,
          );
        }

        return CustomScrollView(
          slivers: <Widget>[
            if (state.isFetchingPlanets)
              SliverFillViewport(
                delegate: SliverChildListDelegate.fixed(
                  [
                    Center(
                      child: const CircularProgressIndicator(),
                    ),
                  ],
                ),
              ),
            if (!state.isFetchingPlanets)
              SliverToBoxAdapter(
                child: HookBuilder(builder: (context) {
                  final buttonAlignment = useMemoized(
                    () {
                      if (null == state.planetPage.previous) {
                        return MainAxisAlignment.end;
                      }
                      if (null == state.planetPage.next) {
                        return MainAxisAlignment.start;
                      }
                      return MainAxisAlignment.spaceBetween;
                    },
                    [state],
                  );

                  return Row(
                    mainAxisAlignment: buttonAlignment,
                    children: <Widget>[
                      if (null != state.planetPage.previous)
                        _LoadPageButton(
                          next: false,
                        ),
                      if (null != state.planetPage.next)
                        _LoadPageButton(
                          next: true,
                        )
                    ],
                  );
                }),
              ),
            if (!state.isFetchingPlanets && state.planetPage.results.isNotEmpty)
              _PlanetList(),
          ],
        );
      },
    );
  }
}

class _Error extends StatelessWidget {
  final String errorMsg;

  const _Error({Key key, this.errorMsg}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<_PlanetHandler>(builder: (context, handler, _) {
      return Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (null != errorMsg) Text(errorMsg),
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
    });
  }
}

class _LoadPageButton extends HookWidget {
  _LoadPageButton({this.next = true}) : assert(next != null);

  final bool next;

  @override
  Widget build(BuildContext context) {
    return Consumer<_PlanetHandler>(
      builder: (context, handler, _) {
        return Consumer<AppState>(
          builder: (context, state, _) {
            return RaisedButton(
              child: next ? const Text('Next Page') : const Text('Prev Page'),
              onPressed: () async {
                final url =
                    next ? state.planetPage.next : state.planetPage.previous;
                await handler.fetchAndDispatch(url);
              },
            );
          },
        );
      },
    );
  }
}

class _PlanetList extends HookWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      return SliverList(
          delegate: SliverChildListDelegate(
        <Widget>[
          for (var planet in state.planetPage.results)
            ListTile(
              title: Text(planet.name),
            )
        ],
      ));
    });
  }
}
