import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<QueryResult>> getQueryResults(String query) async {
  http.Response response = await http.get(
    Uri.parse('https://reykunyu.wimiso.nl/api/fwew?tìpawm=$query'),
  );

  final data = jsonDecode(response.body);

  if (data.length == 0) {
    throw NullThrownError;
  } else if (data.length == 1) {
    var queryResult =
        singleWordQueryResult(data[0]['sì\'eyng'], data[0]['aysämok']);
    // var converted = [
    //   QueryResult(
    //     navi: data[0]['sì\'eyng'][0]['na\'vi'],
    //     type: data[0]['sì\'eyng'][0]['type'],
    //     pronunciation: data[0]['sì\'eyng'][0]['pronunciation'],
    //     infixes: data[0],
    //   )
    // ];
    return queryResult;
  } else {
    print("Not Implemented");
    return multiWordQueryResult(data, query);
  }
}

List<QueryResult> singleWordQueryResult(
    List<dynamic> result, List<String> suggestions) {
  if (result.length == 0) {
    return [];
  }

  List<QueryResult> queryResult = [];

  for (int i = 0; i < result.length; i++) {
    var res = result[i];

    queryResult.add(
      QueryResult(
        navi: SpecialString(text: lemmaForm(res['na\'vi'], res['type'])),
        type: SpecialString(text: toReadableType(res['type'])),
        pronunciation:
            pronunciationToSpecialStrings(res['pronunciation'], res['type']),
        infixes: res.containsKey('infixes')
            ? SpecialString(
                text: res['infixes'].toString().replaceAll('.', '·'))
            : null,
        status: res.containsKey('status')
            ? SpecialString(text: ':warning: ' + res['status'])
            : null,
        //TODO Implement conjugation function and auxillaries
        // conjugation: res.containsKey('conjugated')
        //\     ? conjugation(res['conjugated'])
        //     : null,
      ),
    );
  }

  return queryResult;
}

List<QueryResult> multiWordQueryResult(List<dynamic> result, String query) {
  throw UnimplementedError;
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

String toReadableType(String type) {
  const Map<String, String> mapping = {
    "n": "n.",
    "n:unc": "n.",
    "n:si": "v.",
    "n:pr": "prop. n.",
    "pn": "pn.",
    "adj": "adj.",
    "num": "num.",
    "adv": "adv.",
    "adp": "adp.",
    "adp:len": "adp+",
    "intj": "intj.",
    "part": "part.",
    "conj": "conj.",
    "ctr": "sbd.",
    "v:?": "v.",
    "v:in": "vin.",
    "v:tr": "vtr.",
    "v:m": "vm.",
    "v:si": "v.",
    "v:cp": "vcp.",
    "phr": "phr.",
    "inter": "inter.",
    "aff:pre": "pref.",
    "aff:in": "inf.",
    "aff:suf": "suf."
  };

  return mapping[type] ?? "E0x01";
}

/// Transforms a [pronunciation], which contains a string with dash-separated
/// syllables and a number indicating which syllable is stressed, into special
/// strings for text formatting using the word [type].
List<SpecialString> pronunciationToSpecialStrings(
    List<dynamic> pronunciation, String type) {
  if (pronunciation.isEmpty) {
    return [SpecialString(text: "Unknown stress")];
  }

  List<SpecialString> ret = [];
  List<String> syllables = pronunciation[0].split('-');

  for (int i = 0; i < syllables.length; i++) {
    if (i > 0) {
      ret.add(SpecialString(text: '-'));
    }
    if (syllables.length > 1 && i + 1 == pronunciation[1]) {
      ret.add(SpecialString(text: syllables[i], underlined: true));
    } else {
      ret.add(SpecialString(text: syllables[i]));
    }
  }

  if (type == "n:si") {
    ret.add(SpecialString(text: " si"));
  }

  return ret;
}

class QueryResult {
  final SpecialString navi;
  final SpecialString type;
  final List<SpecialString> pronunciation;
  final SpecialString? infixes;
  final SpecialString? status;
  final SpecialString? conjugation;

  QueryResult({
    required this.navi,
    required this.type,
    required this.pronunciation,
    this.infixes,
    this.status,
    this.conjugation,
  });
}

class SpecialString {
  String text;
  final bool bold;
  final bool italic;
  final bool underlined;

  SpecialString({
    this.text = "",
    this.bold = false,
    this.italic = false,
    this.underlined = false,
  });
}
