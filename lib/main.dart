import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:reykunyapp/api_access.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reykunyapp',
      home: HomePage(
        title: 'Reykunyapp',
      ),
      theme: ThemeData(
        brightness: Brightness.dark,
        textTheme: TextTheme(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<QueryResult> queryResults = [];
  bool reverseSearching = false;

  final List<String> languages = <String>[
    'English',
    'Français',
    'Deutsche',
    'Nederlands',
  ];
  final Map<String, String> languageCodes = {
    'English': 'en',
    'Français': 'fr',
    'Deutsche': 'de',
    'Nederlands': 'nl',
  };
  String chosenLanguage = 'English';
  String chosenLanguageCode = 'en';

  Future<List<QueryResult>> getFutureQueryResults(String query) {
    print('getFutureQueryResults using language: $chosenLanguageCode');
    Future<List<QueryResult>> futureQueryResults = getQueryResults(
        query: query, language: chosenLanguageCode, reversed: reverseSearching);
    return futureQueryResults;
  }

  @override
  Widget build(BuildContext context) {
    print(languageCodes.keys.toList());
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButton(
              hint: Text('Select language'),
              value: chosenLanguage,
              onChanged: (newLanguage) {
                setState(() {
                  chosenLanguage = newLanguage.toString();
                  chosenLanguageCode = languageCodes[chosenLanguage] ?? 'en';
                });
              },
              icon: Icon(Icons.translate),
              items: languages
                  .where(
                      (String language) => languageCodes.containsKey(language))
                  .map<DropdownMenuItem<String>>(
                (String language) {
                  return DropdownMenuItem(
                    value: language,
                    child: Text(language),
                  );
                },
              ).toList(),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(
                () {
                  reverseSearching = !reverseSearching;
                },
              );
            },
            icon: Icon(
              Icons.flip,
              color: reverseSearching
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).disabledColor,
            ),
            tooltip: "Toggle reverse search",
            enableFeedback: true,
          ),
        ],
      ),
      body: Column(
        children: [
          SearchBar(
            callback: (String query) {
              Future<List<QueryResult>> futureQueryResults =
                  getFutureQueryResults(query);
              futureQueryResults.then(
                (value) {
                  setState(() {
                    queryResults = value;
                  });
                },
              );
            },
          ),
          Expanded(
            child: ListView(
              children: [
                for (int i = 0; i < 2 * queryResults.length - 1; i++)
                  if (i % 2 == 0)
                    QueryResultCard(
                      queryResult: queryResults[i ~/ 2],
                    )
                  else
                    Divider(
                      indent: 10,
                      endIndent: 10,
                      thickness: 3.0,
                    )
                // SearchResultRaw(json: queryResults[i].navi.text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SearchBar extends StatefulWidget {
  final Function callback;

  const SearchBar({
    Key? key,
    required this.callback,
  }) : super(key: key);

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController searchBarController = TextEditingController();

  @override
  void dispose() {
    searchBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: searchBarController,
        onSubmitted: (_) {
          widget.callback(searchBarController.text);
        },
        decoration: InputDecoration(
          hintText: "Enter a query",
          suffixIcon: IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              widget.callback(searchBarController.text);
            },
          ),
        ),
      ),
    );
  }
}

class QueryResultCard extends StatelessWidget {
  final QueryResult queryResult;
  const QueryResultCard({
    required this.queryResult,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DeclensionTable declensions = DeclensionTable(queryResult: queryResult);

    try {
      return Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: queryResult.navi + ' ',
                  style: Theme.of(context).textTheme.headline4,
                  children: [
                    TextSpan(
                      text: queryResult.type,
                      style: Theme.of(context).textTheme.headline6,
                    )
                  ],
                ),
              ),
              Text.rich(
                prettyPronunciation(
                    queryResult.pronunciation, queryResult.stress),
              ),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return Divider(
                    endIndent: constraints.maxWidth * 0.9,
                  );
                },
              ),
              Text.rich(
                TextSpan(
                  text: queryResult.translation,
                  style: Theme.of(context).textTheme.headline5,
                ),
              ),
              if (queryResult.meaningNote != null)
                Text.rich(
                  TextSpan(
                    text: queryResult.meaningNote,
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                ),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return Divider(
                    endIndent: constraints.maxWidth * 0.9,
                  );
                },
              ),
              if (queryResult.affixes?.isNotEmpty ?? false)
                Text("Affixes: ", style: Theme.of(context).textTheme.headline6),
              Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Column(
                  children: [
                    for (int i = 0;
                        i < (queryResult.affixes?.length ?? 0);
                        i += 2)
                      Text(
                        '${queryResult.affixes![i]}: ${queryResult.affixes![i + 1]}',
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                  ],
                ),
              ),
              if (queryResult.declensions != null &&
                  queryResult.declensions!.isNotEmpty)
                declensions
              // Table(
              //   defaultColumnWidth: FlexColumnWidth(),
              //   children: [
              //     TableRow(
              //       children: [
              //         Container(),
              //         for (String plurality in [
              //           'singular',
              //           'dual',
              //           'trial',
              //           'plural',
              //         ])
              //           Text(
              //             plurality,
              //             style: TextStyle(
              //                 fontWeight: FontWeight.bold, fontSize: 14),
              //           )
              //       ],
              //     ),
              //     for (int i = 0; i < queryResult.declensions![0].length; i++)
              //       TableRow(
              //         children: [
              //           Padding(
              //             padding: const EdgeInsets.only(right: 8.0),
              //             child: Text(
              //               [
              //                 'subjective',
              //                 'agentive',
              //                 'patientive',
              //                 'dative',
              //                 'genitive',
              //                 'topical'
              //               ][i],
              //               style: TextStyle(
              //                   fontWeight: FontWeight.bold, fontSize: 14),
              //               textAlign: TextAlign.right,
              //             ),
              //           ),
              //           for (int j = 0;
              //               j < (queryResult.declensions?.length ?? 0);
              //               j++)
              //             RichText(
              //               text: parseDeclension(
              //                 // TextSpan(
              //                 queryResult.declensions![j][i].text,
              //               ),
              //             ),
              //         ],
              //       ),
              //   ],
              // ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('${queryResult.navi} is causing problems');
      return Container(
        child: Text(
          "ERROR (${queryResult.navi}): ${e}",
          textAlign: TextAlign.center,
        ),
      );
    }
  }
}

class DeclensionTable extends StatelessWidget {
  final QueryResult queryResult;
  const DeclensionTable({required QueryResult this.queryResult, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 200.0,
        child: ListView(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          children: [
            // Declension names
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Empty cell top-left of the table
                Text(" "),
                for (String form in [
                  'subjective',
                  'agentive',
                  'patientive',
                  'dative',
                  'genitive',
                  'topical',
                ])
                  Text(
                    form,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            SizedBox(
              width: 16.0,
            ),
            // Actual declensions
            for (int plurality = 0;
                plurality < queryResult.declensions!.length;
                plurality++) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ["singular", "dual", "trial", "plural"][plurality],
                  ),
                  for (int declension = 0;
                      declension < queryResult.declensions![0].length;
                      declension++)
                    RichText(
                      text: parseDeclension(
                        queryResult.declensions![plurality][declension],
                      ),
                    ),
                ],
              ),
              SizedBox(
                width: 32.0,
              ),
            ]
          ],
        ),
      ),
    );
  }
}

TextSpan prettyPronunciation(List<String> pronunciation, int stress) {
  return TextSpan(
    children: [
      for (int i = 0; i < pronunciation.length; i++)
        TextSpan(
          text: pronunciation[i],
          style: TextStyle(
              fontStyle: i == stress ? FontStyle.italic : FontStyle.normal),
        ),
    ],
  );
}

TextSpan parseDeclension(String declension) {
  TextSpan output = TextSpan(children: []);

  RegExp matchPrefix = RegExp(r'\(?([a-zìäé ]*)-\)?', caseSensitive: false);
  RegExp matchLenition = RegExp(r'(?<=\{)(.*)(?=\})', caseSensitive: false);
  RegExp matchRoot =
      RegExp(r'(?<=[^a-zìäé])([a-zìäé ]*)(?=\-)', caseSensitive: false);
  RegExp matchSuffix = RegExp(r'-[a-zìäé ]*', caseSensitive: false);

  String? prefix = matchPrefix.firstMatch(declension)?.group(0) ?? "";
  String? lenition = matchLenition.firstMatch(declension)?.group(0) ?? "";
  String? root = matchRoot.allMatches(declension).isNotEmpty
      ? matchRoot.allMatches(declension).last.group(0)
      : "";
  String? suffix = matchSuffix.allMatches(declension).isNotEmpty
      ? matchSuffix.allMatches(declension).last.group(0)
      : "";

  output.children
    ?..add(
      TextSpan(
        text: prefix.length > 1 ? prefix : "",
        style: TextStyle(color: Colors.red[300]),
      ),
    )
    ..add(
      TextSpan(
        text: lenition,
        style: TextStyle(color: Colors.green[300]),
      ),
    )
    ..add(
      TextSpan(
        text: root,
        style: TextStyle(color: Colors.grey[300]),
      ),
    )
    ..add(
      TextSpan(
        text: (suffix?.length ?? 0) > 1 ? suffix : "",
        style: TextStyle(color: Colors.blue[300]),
      ),
    );

  return output;
}

// Placeholders
Color randomColor() {
  Random rand = Random();
  return Color.fromARGB(
      255, rand.nextInt(255), rand.nextInt(255), rand.nextInt(255));
}
