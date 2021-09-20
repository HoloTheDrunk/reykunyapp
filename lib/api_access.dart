import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:reykunyapp/nouns.dart' as nouns;

Future<List<QueryResult>> getQueryResults(
    {required String query,
    required String language,
    required bool reversed}) async {
  http.Response response;
  if (!reversed) {
    response = await http.get(
      Uri.parse('https://reykunyu.wimiso.nl/api/fwew?tìpawm=$query'),
    );
  } else {
    response = await http.get(
      Uri.parse(
          'https://reykunyu.wimiso.nl/api/search?language=$language&query=$query'),
    );
  }

  if (response.contentLength == 0) {
    return [];
  }
  print(response.body);

  final data = jsonDecode(response.body);

  if (data.length == 0) {
    return [];
  } else if (data.length == 1) {
    return singleWordQueryResult(data[0]['sì\'eyng'], language: language);
  } else {
    return singleWordQueryResult(data, language: language);
  }
}

Future<String?> getAnnotatedDictionaryEntry({required String naviQuery}) async {
  http.Response? dictResponse = await http.get(
    Uri.parse(
        'https://reykunyu.wimiso.nl/api/annotated/search?query=$naviQuery'),
  );
  return jsonDecode(dictResponse.body)[0];
}

Future<List<QueryResult>> singleWordQueryResult(List<dynamic> result,
    {List<dynamic>? suggestions, String language = 'en'}) async {
  List<QueryResult> queryResults = [];

  for (int i = 0; i < result.length; i++) {
    var res = result[i];

    String? dictEntry =
        await getAnnotatedDictionaryEntry(naviQuery: res['na\'vi']);

    final rawDeclensions =
        res.containsKey('conjugation') ? res['conjugation']['forms'] : null;
    List<List<String>>? declensions = [];

    if (rawDeclensions != null) {
      for (var l in rawDeclensions) {
        List<String> row = [];
        for (var s in l) {
          row.add(s.toString());
        }
        declensions.add(row);
      }
    } else if (res['type'] == 'n') {
      declensions = createNounDeclensions(res['na\'vi'], false);
    } else if (res['type'] == 'n:pr') {
      declensions = createNounDeclensions(res['na\'vi'], true);
    } else {
      declensions = null;
    }
    print(declensions);

    queryResults.add(
      QueryResult(
        navi: lemmaForm(res['na\'vi'], res['type']),
        type: toReadableType(res['type']),
        pronunciation: res.containsKey('pronunciation')
            ? pronunciationToList(res['pronunciation'], res['type'])
            : ["Unknown stress pattern"],
        stress: res.containsKey('pronunciation') ? res['pronunciation'][1] : 0,
        infixes: res.containsKey('infixes')
            ? res['infixes'].toString().replaceAll('.', '·')
            : null,
        status: res.containsKey('status') ? ':warning: ' + res['status'] : null,
        conjugation: res.containsKey('conjugated')
            ? conjugation(conjugated: res['conjugated'], short: false)
            : null,
        translation: res.containsKey('translations')
            ? getTranslation(res['translations'][0], language: language)
            : "Missing translation section",
        meaningNote:
            res.containsKey('meaning_note') ? res['meaning_note'] : null,
        affixes: res.containsKey('affixes')
            ? affixesSection(res['affixes'], language: language)
            : null,
        declensions: declensions,
        annotatedDictEntry: dictEntry,
      ),
    );
  }

  return queryResults;
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
/// syllables and a number indicating which syllable is stressed into strings
/// for text formatting according to the word [type].
List<String> pronunciationToList(List<dynamic> pronunciation, String type) {
  if (pronunciation.isEmpty) {
    return ["Unknown stress"];
  }

  List<String> ret = [];
  List<String> syllables = pronunciation[0].split('-');

  for (int i = 0; i < syllables.length; i++) {
    if (i > 0) {
      ret.add('-');
    }
    if (syllables.length > 1 && i + 1 == pronunciation[1]) {
      ret.add(syllables[i]);
    } else {
      ret.add(syllables[i]);
    }
  }

  if (type == "n:si") {
    ret.add(" si");
  }

  return ret;
}

List<String> conjugation({var conjugated, bool short = false}) {
  List<String> result = [];

  for (int i = 0; i < conjugated.length; i++) {
    String type = conjugated[i]['type'];
    var conjugation = conjugated[i]['conjugation'];

    // Continue if not conjugated
    if (conjugation['result'].toLowerCase() ==
        conjugation['root'].toLowerCase()) {
      continue;
    }

    // Add separators starting from first element
    if (result.isNotEmpty) {
      result.add(short ? ';' : '\n');
    }

    switch (type) {
      case 'n':
        result += nounConjugation(conjugation: conjugation, short: short);
        break;
      case 'v':
        result += verbConjugation(conjugation: conjugation, short: short);
        break;
      case 'adj':
        result += adjectiveConjugation(conjugation: conjugation, short: short);
        break;
      case 'v_to_n':
        result += verbToNounConjugation(conjugation: conjugation, short: short);
        break;
      default:
        throw ArgumentError;
    }
  }

  return result;
}

List<String> nounConjugation({var conjugation, bool short = false}) {
  List<String> result = [short ? '< ' : '→ '];

  for (int i = 0; i <= 2; i++) {
    if (conjugation['affixes'][i].toString().isNotEmpty) {
      result.add('${conjugation['affixes'][i]} + ');
    }
  }

  result.add(conjugation['root']);

  for (int i = 3; i <= 6; i++) {
    if (conjugation['affixes'][i].toString().isNotEmpty) {
      result.add(' + ${conjugation['affixes'][i]}');
    }
  }

  if (!short) {
    result
      ..add(" = ")
      ..add(conjugation['result']);
  }

  return result;
}

List<String> verbConjugation({var conjugation, bool short = false}) {
  List<String> result = [short ? '< ' : '→ '];
  result.add(conjugation['root']);

  for (int i = 0; i < 3; i++) {
    if (conjugation['infixes'][i].toString().isNotEmpty) {
      result.add(' + <${conjugation['infixes'][i]}>');
    }
  }

  if (!short) {
    result
      ..add(" = ")
      ..add(conjugation['result']);
  }

  return result;
}

List<String> adjectiveConjugation({var conjugation, bool short = false}) {
  List<String> result = [short ? '< ' : '→ '];

  if (conjugation['form'] == 'postnoun') {
    result.add("a + ");
  }

  result.add(conjugation['root']);

  if (conjugation['form'] == 'prenoun') {
    result.add(" + a");
  }

  if (!short) {
    result
      ..add(" = ")
      ..add(conjugation['result']);
  }

  return result;
}

List<String> verbToNounConjugation({var conjugation, bool short = false}) {
  List<String> result = [short ? '< ' : '→ '];

  result
    ..add(conjugation['root'])
    ..add(' + ${conjugation['affixes'][0]}');

  if (!short) {
    result
      ..add(" = ")
      ..add(conjugation['result']);
  }

  return result;
}

String getTranslation(Map<String, dynamic> translations,
    {required String language}) {
  if (translations.isNotEmpty) {
    //   print('$language => ${translations[language].toString()}');
    // The bang operator use here is kinda nasty ngl
    return translations.containsKey(language)
        ? translations[language]!.toString()
        : 'N/A';
  } else {
    return 'Missing translation';
  }
}

List<String>? affixesSection(List<dynamic> affixes,
    {required String language}) {
  List<String>? result = [];
  for (var affixParent in affixes) {
    final affix = affixParent['affix'];
    result
      ..add(lemmaForm(affix['na\'vi'], affix['type']))
      ..add(getTranslation(affix['translations'][0], language: language));
  }
  return result;
}

List<List<String>> createNounDeclensions(String word, bool uncountable) {
  List<List<String>> declensions = [];
  List<Function> caseFunctions = [
    nouns.subjective,
    nouns.agentive,
    nouns.patientive,
    nouns.dative,
    nouns.genitive,
    nouns.topical
  ];
  List<String> plurals = [
    nouns.singular(word),
    nouns.dual(word),
    nouns.trial(word),
    nouns.plural(word)
  ];

  for (int i = 0; i < 4; i++) {
    List<String> row = [];
    if (!uncountable || i == 0) {
      for (int j = 0; j < 6; j++) {
        row.add(caseFunctions[j](plurals[i]));
      }
    }
    declensions.add(row);
  }

  declensions =
      declensions.where((List<String> lss) => lss.isNotEmpty).toList();
  declensions += List<List<String>>.generate(
    4 - declensions.length,
    (__) => List<String>.generate(
      6,
      (_) => '-x-',
    ),
  );
  return declensions;
}

class QueryResult {
  final String navi;
  final String type;
  final List<String> pronunciation;
  final int stress;
  final String translation;
  final String? infixes;
  final String? status;
  final List<String>? conjugation;
  final String? meaningNote;
  final List<String>? affixes;
  final List<List<String>>? declensions;
  final String? annotatedDictEntry;

  const QueryResult({
    required this.navi,
    required this.type,
    required this.pronunciation,
    required this.stress,
    required this.translation,
    this.infixes,
    this.status,
    this.conjugation,
    this.meaningNote,
    this.affixes,
    this.declensions,
    this.annotatedDictEntry,
  });
}
