import 'dart:convert';

import 'package:flutter_hooks_gallery/star_wars/models.dart';
import 'package:http/http.dart' as http;

/// Api wrapper to retrieve Star Wars related data
class StarWarsApi {
  /// load and return one page of planets
  Future<PlanetPageModel> getPlanets(String page) async {
    page ??= 'https://swapi.co/api/planets';
    final response = await http.get(page);
    dynamic json = jsonDecode(utf8.decode(response.bodyBytes));

    return serializers.deserializeWith(PlanetPageModel.serializer, json);
  }
}
