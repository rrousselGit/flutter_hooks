import 'package:built_value/built_value.dart';
import 'package:flutter_hooks_gallery/star_wars/models.dart';

part 'app_state.g.dart';

abstract class AppState implements Built<AppState, AppStateBuilder> {
  PlanetPageModel get planetPage;

  AppState._();
  factory AppState([void Function(AppStateBuilder) updates]) = _$AppState;
}
