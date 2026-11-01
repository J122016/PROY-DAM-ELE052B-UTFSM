import 'dart:collection';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ExampleProvider {
  final String apiURL = 'http://10.0.2.2:8000/api'; // url for connect to localhost from Android VM

  Future<List<dynamic>> getValue() async {
    var uri = Uri.parse('$apiURL/example');
    var response = await http.get(uri);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return [];
    }
  }

  Future<LinkedHashMap<String, dynamic>> AddValue(
    String value,
  ) async {
    var uri = Uri.parse('$apiURL/model');
    var response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'aplication/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, String>{'value': value}),
    );
    return json.decode(response.body);
  }

  Future<bool> deleteValue(int id) async {
    var uri = Uri.parse('$apiURL/model/$id');
    var response = await http.delete(uri);
    return response.statusCode == 200;
  }
}
