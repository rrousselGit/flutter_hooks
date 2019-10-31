import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';

part 'models.g.dart';

@SerializersFor([
  PlanetPageModel,
  PlanetModel,
])

/// json serializer to build models
final Serializers serializers =
    (_$serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();

/// equals one page
abstract class PlanetPageModel
    implements Built<PlanetPageModel, PlanetPageModelBuilder> {
  /// serialize the model
  static Serializer<PlanetPageModel> get serializer =>
      _$planetPageModelSerializer;

  /// url to next page
  @nullable
  String get next;

  /// url to prev page
  @nullable
  String get previous;

  /// all planets
  BuiltList<PlanetModel> get results;

  PlanetPageModel._();

  /// default factory
  factory PlanetPageModel([void Function(PlanetPageModelBuilder) updates]) =
      _$PlanetPageModel;
}

/// equals one planet
abstract class PlanetModel implements Built<PlanetModel, PlanetModelBuilder> {
  /// serialize the model
  static Serializer<PlanetModel> get serializer => _$planetModelSerializer;

  /// planet name
  String get name;

  PlanetModel._();

  /// default factory
  factory PlanetModel([void Function(PlanetModelBuilder) updates]) =
      _$PlanetModel;
}
