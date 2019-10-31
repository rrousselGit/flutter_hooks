import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_hooks_gallery/star_wars/app_state.dart';
import 'package:flutter_hooks_gallery/star_wars/hooks.dart';
import 'package:flutter_hooks_gallery/star_wars/redux.dart';
import 'package:flutter_hooks_gallery/star_wars/star_wars_api.dart';
import 'package:provider/provider.dart';

/// This example will load, show and let you navigate through all star wars
/// planets.
///
/// It will demonstrate on how to use [Provider] and redux ([useReducer])
class PlanetList extends HookWidget {
  @override
  Widget build(BuildContext context) {
    /// create single instance of Star Wars Api
    final api = useMemoized(() => StarWarsApi());

    /// create single instance of redux store
    final store = useReducer(
      reducer,
      initialState: AppState(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Star Wars Planets',
        ),
      ),

      /// provide star wars api instance,
      /// redux store instance
      /// and redux state down the widget tree.
      body: MultiProvider(
        providers: [
          Provider.value(value: api),
          Provider.value(value: store),
          Provider.value(value: store.state),
        ],
        child: HookBuilder(
          builder: (context) {
            final state = useAppState();
            final store = useAppStore();
            final isLoadingState = useState(false);

            final fetchAndDispatchPlanets =
                useMemoized<FetchAndDispatchPlanets>(
              () => ([String url]) async {
                isLoadingState.value = true;
                final page = await api.getPlanets(url);
                store.dispatch(SetPlanetPageAction(page));
                isLoadingState.value = false;
              },
              [store],
            );

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

            /// load the first planet page but only on the first build
            useEffect(
              () {
                fetchAndDispatchPlanets(null);
                return () {};
              },
              const [],
            );

            return Provider.value(
              value: fetchAndDispatchPlanets,
              child: CustomScrollView(
                slivers: <Widget>[
                  if (isLoadingState.value)
                    SliverToBoxAdapter(
                      child: Center(child: const CircularProgressIndicator()),
                    ),
                  if (!isLoadingState.value)
                    SliverToBoxAdapter(
                      child: Row(
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
                      ),
                    ),
                  if (!isLoadingState.value &&
                      state.planetPage.results.isNotEmpty)
                    _List(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoadPageButton extends HookWidget {
  final bool next;

  _LoadPageButton({this.next = true}) : assert(next != null);

  @override
  Widget build(BuildContext context) {
    final state = useAppState();
    final fetchAndDispatch = useFetchAndDispatchPlanets();

    return RaisedButton(
      child: next ? const Text('Next Page') : const Text('Prev Page'),
      onPressed: () async {
        final url = next ? state.planetPage.next : state.planetPage.previous;
        await fetchAndDispatch(url);
      },
    );
  }
}

class _List extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final state = useAppState();
    return SliverList(
      delegate: SliverChildListDelegate(
        state.planetPage.results
            .map((planet) => ListTile(
                  title: Text(planet.name),
                ))
            .toList(),
      ),
    );
  }
}
