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
    List<dynamic> result, List<String> suggestions) {
  if (result.length == 0) {
    if (suggestions.length != 0) {
      return suggestions;
    } else {
      return ["No results found."];
    }
  }

  List<String> queryResult = [];

  for (int i = 0; i < result.length; i++) {
    var res = result[i];
    //TODO Handle each result
  }

  return queryResult;
}

List<String> multiWordQueryResult(List<dynamic> result, String query) {
  //! Not implemented
  return [];
}

String lemmaForm(String word, String type) {
  if (type == "n:si") {
    return word + ' si';
  } else if (type == 'aff:pre') {
    return word + "-";
  } else if (type == 'aff:in') {
    return '‹' + word + '›';
  } else if (type == 'aff:suf') {
    return '-' + word;
  }
  return word;
}
