// ignore_for_file: public_member_api_docs

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';

part 'models.g.dart';

/// json serializer to build models
@SerializersFor([
  PlanetPageModel,
  PlanetModel,
])
final Serializers serializers =
    (_$serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();

/// equals one page
abstract class PlanetPageModel
    implements Built<PlanetPageModel, PlanetPageModelBuilder> {
  PlanetPageModel._();

  factory PlanetPageModel([void Function(PlanetPageModelBuilder) updates]) =
      _$PlanetPageModel;

  static Serializer<PlanetPageModel> get serializer =>
      _$planetPageModelSerializer;

  @nullable
  String get next;

  @nullable
  String get previous;

  BuiltList<PlanetModel> get results;
}

/// equals one planet
abstract class PlanetModel implements Built<PlanetModel, PlanetModelBuilder> {
  PlanetModel._();

  factory PlanetModel([void Function(PlanetModelBuilder) updates]) =
      _$PlanetModel;

  static Serializer<PlanetModel> get serializer => _$planetModelSerializer;

  String get name;
}
