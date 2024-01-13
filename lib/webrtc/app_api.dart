import 'dart:convert';

import 'package:http/http.dart' as http;

class AppAPI {
  late String _baseUrl;

  AppAPI({baseUrl}) {
    _baseUrl = baseUrl;
  }

  Future<String> getId() async {
    final ts = DateTime.now().microsecondsSinceEpoch.toString();
    final url = "$_baseUrl/id?ts=$ts&version=1";
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Error.Status:${response.statusCode}');
      }
      return response.body;
    } catch (error) {
      throw Exception("Could not get an ID from the server.$url");
    }
  }

  Future<List<String>> getPeers() async {
    final url = "$_baseUrl/peers";
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Error.Status:${response.statusCode}');
      }
      List<dynamic> jsonList = json.decode(response.body);

      return List<String>.from(jsonList);
    } catch (error) {
      throw Exception("Could not get peers from the server.$url");
    }
  }

}
