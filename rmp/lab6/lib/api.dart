import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lab6/models.dart';

Future<List<dynamic>> getCharacterData() async {
  Uri url = Uri.parse("https://hp-api.onrender.com/api/characters");
  final response = await http.get(url,);

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception("Error: ${response.reasonPhrase}");
  }
}
