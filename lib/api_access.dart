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

List<QueryResult> singleWordQueryResult(List<dynamic> result,
    {List<dynamic>? suggestions, String language = 'en'}) {
  if (result.length == 0) {
    return [];
  }

  List<QueryResult> queryResults = [];

  for (int i = 0; i < result.length; i++) {
    var res = result[i];

    final rawDeclensions =
        res.containsKey('conjugation') ? res['conjugation']['forms'] : null;
    List<List<SpecialString>>? declensions = [];

    if (rawDeclensions != null) {
      for (var l in rawDeclensions) {
        List<SpecialString> row = [];
        for (var s in l) {
          row.add(SpecialString(text: s.toString()));
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

    queryResults.add(
      QueryResult(
        navi: SpecialString(
            text: lemmaForm(res['na\'vi'], res['type']), bold: true),
        type: SpecialString(text: toReadableType(res['type'])),
        pronunciation: res.containsKey('pronunciation')
            ? pronunciationToSpecialStrings(res['pronunciation'], res['type'])
            : [SpecialString(text: "Unknown stress pattern")],
        infixes: res.containsKey('infixes')
            ? SpecialString(
                text: res['infixes'].toString().replaceAll('.', '·'))
            : null,
        status: res.containsKey('status')
            ? SpecialString(text: ':warning: ' + res['status'])
            : null,
        conjugation: res.containsKey('conjugated')
            ? conjugation(conjugated: res['conjugated'], short: false)
            : null,
        translation: res.containsKey('translations')
            ? getTranslation(res['translations'][0], language: language)
            : SpecialString(text: "Missing translation section"),
        meaningNote: res.containsKey('meaning_note')
            ? SpecialString(text: res['meaning_note'])
            : null,
        affixes: res.containsKey('affixes')
            ? affixesSection(res['affixes'], language: language)
            : null,
        declensions: declensions,
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

List<SpecialString> conjugation({var conjugated, bool short = false}) {
  List<SpecialString> result = [];

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
      result.add(SpecialString(text: short ? ';' : '\n'));
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

List<SpecialString> nounConjugation({var conjugation, bool short = false}) {
  List<SpecialString> result = [SpecialString(text: short ? '< ' : '→ ')];

  for (int i = 0; i <= 2; i++) {
    if (conjugation['affixes'][i].toString().isNotEmpty) {
      result.add(SpecialString(text: '${conjugation['affixes'][i]} + '));
    }
  }

  result.add(SpecialString(text: conjugation['root']));

  for (int i = 3; i <= 6; i++) {
    if (conjugation['affixes'][i].toString().isNotEmpty) {
      result.add(SpecialString(text: ' + ${conjugation['affixes'][i]}'));
    }
  }

  if (!short) {
    result
      ..add(SpecialString(text: " = "))
      ..add(SpecialString(text: conjugation['result'], bold: true));
  }

  return result;
}

List<SpecialString> verbConjugation({var conjugation, bool short = false}) {
  List<SpecialString> result = [SpecialString(text: short ? '< ' : '→ ')];
  result.add(SpecialString(text: conjugation['root']));

  for (int i = 0; i <= 3; i++) {
    if (conjugation['infixes'][i].toString().isNotEmpty) {
      result.add(SpecialString(text: ' + <${conjugation['infixes'][i]}>'));
    }
  }

  if (!short) {
    result
      ..add(SpecialString(text: " = "))
      ..add(SpecialString(text: conjugation['result'], bold: true));
  }

  return result;
}

List<SpecialString> adjectiveConjugation(
    {var conjugation, bool short = false}) {
  List<SpecialString> result = [SpecialString(text: short ? '< ' : '→ ')];

  if (conjugation['form'] == 'postnoun') {
    result.add(SpecialString(text: "a + "));
  }

  result.add(SpecialString(text: conjugation['root']));

  if (conjugation['form'] == 'prenoun') {
    result.add(SpecialString(text: " + a"));
  }

  if (!short) {
    result
      ..add(SpecialString(text: " = "))
      ..add(SpecialString(text: conjugation['result'], bold: true));
  }

  return result;
}

List<SpecialString> verbToNounConjugation(
    {var conjugation, bool short = false}) {
  List<SpecialString> result = [SpecialString(text: short ? '< ' : '→ ')];

  result
    ..add(SpecialString(text: conjugation['root']))
    ..add(SpecialString(text: ' + ${conjugation['affixes'][0]}'));

  if (!short) {
    result
      ..add(SpecialString(text: " = "))
      ..add(SpecialString(text: conjugation['result'], bold: true));
  }

  return result;
}

SpecialString getTranslation(Map<String, dynamic> translations,
    {required String language}) {
  if (translations.isNotEmpty) {
    print('$language => ${translations[language].toString()}');
    return SpecialString(
        // The bang operator use here is kinda nasty ngl
        text: translations.containsKey(language)
            ? translations[language]!.toString()
            // : translations.containsKey('en')
            //     ? translations['en']!.toString()
            : 'Missing translation');
  } else {
    return SpecialString(text: 'Missing translation');
  }
}

List<SpecialString>? affixesSection(List<dynamic> affixes,
    {required String language}) {
  List<SpecialString>? result = [];
  for (var affixParent in affixes) {
    final affix = affixParent['affix'];
    result
      ..add(SpecialString(
          text: lemmaForm(affix['na\'vi'], affix['type']), bold: true))
      ..add(getTranslation(affix['translations'][0], language: language));
  }
  return result;
}

List<List<SpecialString>> createNounDeclensions(String word, bool uncountable) {
  List<List<SpecialString>> declensions = [];
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
    declensions.add(row.map((String s) => SpecialString(text: s)).toList());
  }

  declensions =
      declensions.where((List<SpecialString> lss) => lss.isNotEmpty).toList();
  declensions += List<List<SpecialString>>.generate(
    4 - declensions.length,
    (__) => List<SpecialString>.generate(
      6,
      (_) => SpecialString(text: '-x-'),
    ),
  );
  return declensions;
}

class QueryResult {
  final SpecialString navi;
  final SpecialString type;
  final List<SpecialString> pronunciation;
  final SpecialString translation;
  final SpecialString? infixes;
  final SpecialString? status;
  final List<SpecialString>? conjugation;
  final SpecialString? meaningNote;
  final List<SpecialString>? affixes;
  final List<List<SpecialString>>? declensions;

  const QueryResult({
    required this.navi,
    required this.type,
    required this.pronunciation,
    required this.translation,
    this.infixes,
    this.status,
    this.conjugation,
    this.meaningNote,
    this.affixes,
    this.declensions,
  });
}

class SpecialString {
  final String text;
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
