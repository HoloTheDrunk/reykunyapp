import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<String>> getQueryResult(String query) async {
  http.Response response = await http.get(
    Uri.parse('https://reykunyu.wimiso.nl/api/fwew?tìpawm=$query'),
  );

  final data = jsonDecode(response.body);

  if (data.length == 0) {
    return [];
  } else if (data.length == 1) {
    return singleWordQueryResult(data[0]['sì\'eyng'], data[0]['aysämok']);
  } else {
    return multiWordQueryResult(data, query);
  }
}

List<String> singleWordQueryResult(
    List<dynamic> result, List<dynamic> suggestions) {
  //! Not implemented
  return [];
}

List<String> multiWordQueryResult(List<dynamic> result, String query) {
  //! Not implemented
  return [];
}
