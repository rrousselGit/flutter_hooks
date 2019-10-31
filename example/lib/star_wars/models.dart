// ignore_for_file: public_member_api_docs

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';

part 'models.g.dart';

@SerializersFor([
  PlanetPageModel,
  PlanetModel,
])
final Serializers serializers =
    (_$serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();

abstract class PlanetPageModel
    implements Built<PlanetPageModel, PlanetPageModelBuilder> {
  static Serializer<PlanetPageModel> get serializer =>
      _$planetPageModelSerializer;
  @nullable
  String get next;

  @nullable
  String get previous;

  BuiltList<PlanetModel> get results;

  PlanetPageModel._();
  factory PlanetPageModel([void Function(PlanetPageModelBuilder) updates]) =
      _$PlanetPageModel;
}

abstract class PlanetModel implements Built<PlanetModel, PlanetModelBuilder> {
  static Serializer<PlanetModel> get serializer => _$planetModelSerializer;
  String get name;
  String get diameter;
  String get climate;
  String get terrain;
  String get population;
  String get url;

  PlanetModel._();
  factory PlanetModel([void Function(PlanetModelBuilder) updates]) =
      _$PlanetModel;
}
