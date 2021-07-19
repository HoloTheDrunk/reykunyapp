import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:reykunyapp/nouns.dart' as nouns;

Future<List<QueryResult>> getQueryResults(String query, String language) async {
  http.Response response = await http.get(
    Uri.parse('https://reykunyu.wimiso.nl/api/fwew?tìpawm=$query'),
  );

  final data = jsonDecode(response.body);

  if (data.length == 0) {
    throw NullThrownError;
  } else if (data.length == 1) {
    return singleWordQueryResult(data[0]['sì\'eyng'], data[0]['aysämok']);
  } else {
    print("Unimplemented");
    return multiWordQueryResult(data, query);
  }
}

List<QueryResult> singleWordQueryResult(
    List<dynamic> result, List<String> suggestions,
    {String language = 'en'}) {
  if (result.length == 0) {
    return [];
  }

  List<QueryResult> queryResults = [];

  for (int i = 0; i < result.length; i++) {
    var res = result[i];

    queryResults.add(
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
        conjugation: res.containsKey('conjugated')
            ? conjugation(conjugated: res['conjugated'], short: false)
            : null,
        translation: getTranslation(res['translations'][0], language: language),
        meaningNote: res['meaning_note'],
        affixes: affixesSection(res['affixes']),
      ),
    );
  }

  return queryResults;
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
    if (conjugation['affixes'][i]) {
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

SpecialString getTranslation(Map<String, String> translations,
    {String language = 'en'}) {
  if (translations.isNotEmpty) {
    return SpecialString(
        // The bang operator use here is kinda nasty ngl
        text: translations.containsKey(language)
            ? translations[language]!
            : translations.containsKey('en')
                ? translations['en']!
                : 'Missing translation');
  } else {
    return SpecialString(text: 'Missing translation');
  }
}

List<SpecialString>? affixesSection(List<dynamic> affixes) {
  List<SpecialString>? result = [];
  for (var affixParent in affixes) {
    final affix = affixParent['affix'];
    result
      ..add(SpecialString(
          text: lemmaForm(affix['na\'vi'], affix['type']), bold: true))
      ..add(getTranslation(affix['translations'][0]));
  }
  return result;
}

List<SpecialString>? nounConjugationSection(List<dynamic> conjugation) {
  List<SpecialString> result;

  for (int i = 1; i < 4; i++) {
    if (conjugation[i].isEmpty) {}
  }
}

List<List<SpecialString>>? createNounConjugation(
    String word, String type, bool uncountable) {
  List<List<SpecialString>> conjugation = [];
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
        row.add(caseFunctions[i](plurals[j]));
      }
    }
    conjugation.add(row
        .map((String conjugatedNoun) => SpecialString(text: conjugatedNoun))
        .toList());
  }

  return conjugation;
}

class QueryResult {
  final SpecialString navi;
  final SpecialString type;
  final List<SpecialString> pronunciation;
  final SpecialString? infixes;
  final SpecialString? status;
  final List<SpecialString>? conjugation;
  final SpecialString translation;
  final SpecialString? meaningNote;
  final List<SpecialString>? affixes;

  QueryResult({
    required this.navi,
    required this.type,
    required this.pronunciation,
    required this.translation,
    this.infixes,
    this.status,
    this.conjugation,
    this.meaningNote,
    this.affixes,
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
