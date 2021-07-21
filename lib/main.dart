import 'dart:math';

import 'package:flutter/material.dart';
import 'package:reykunyapp/api_access.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reykunyapp',
      home: HomePage(title: 'Reykunyapp'),
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
  Random rand = Random();

  Future<List<QueryResult>> getFutureQueryResults(String query) {
    Future<List<QueryResult>> futureQueryResults =
        getQueryResults(query: query, language: 'en');
    return futureQueryResults;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
    TextSpan pronunciation = TextSpan(children: []);
    for (int i = 0; i < queryResult.pronunciation.length; i++) {
      pronunciation.children?.add(
        TextSpan(
          text: queryResult.pronunciation[i].text,
          style: TextStyle(
              decoration: queryResult.pronunciation[i].underlined
                  ? TextDecoration.underline
                  : TextDecoration.none),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                text: queryResult.navi.text + ' ',
                style: Theme.of(context).textTheme.headline4,
                children: [
                  TextSpan(
                    text: queryResult.type.text,
                    style: Theme.of(context).textTheme.headline6,
                  )
                ],
              ),
            ),
            Text.rich(
              pronunciation,
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
                text: queryResult.translation.text,
                style: Theme.of(context).textTheme.headline5,
              ),
            ),
            if (queryResult.meaningNote != null)
              Text.rich(
                TextSpan(
                  text: queryResult.meaningNote?.text,
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
            for (int i = 0; i < (queryResult.affixes?.length ?? 0); i += 2)
              Text(
                '${queryResult.affixes![i].text}: ${queryResult.affixes![i + 1].text}',
                style: Theme.of(context).textTheme.bodyText1,
              ),
            if (queryResult.declensions != null)
              Table(
                defaultColumnWidth: FlexColumnWidth(),
                columnWidths: {0: FractionColumnWidth(.15)},
                children: [
                  TableRow(
                    children: [
                      Container(),
                      for (String plurality in [
                        'singular',
                        'dual',
                        'trial',
                        'plural'
                      ])
                        Text(plurality,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14))
                    ],
                  ),
                  for (int i = 0; i < queryResult.declensions![0].length; i++)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            [
                              'subjective',
                              'agentive',
                              'patientive',
                              'dative',
                              'genitive',
                              'topical'
                            ][i],
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        for (int j = 0;
                            j < (queryResult.declensions?.length ?? 0);
                            j++)
                          // Text("lmao", style: TextStyle(color: randomColor())),
                          RichText(
                            textScaleFactor: 0.8,
                            text: parseDeclension(
                                queryResult.declensions![j][i].text),
                          )
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

TextSpan parseDeclension(String declension) {
  TextSpan output = TextSpan(children: []);

  RegExp matchPrefix = RegExp(r'\(?([a-zìäé]*)-\)?');
  RegExp matchLenition = RegExp(r'(?<=\{)(.*)(?=\})');
  RegExp matchRoot = RegExp(r'(?<=[^a-zìäé])([a-zìäé]*)(?=\-)');
  RegExp matchSuffix = RegExp(r'-[a-zìäé]*');

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

class SpecialText extends StatelessWidget {
  final SpecialString data;
  const SpecialText({required this.data, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      data.text,
      style: TextStyle(
        fontWeight: data.bold ? FontWeight.bold : FontWeight.normal,
        fontStyle: data.italic ? FontStyle.italic : FontStyle.normal,
        decoration:
            data.underlined ? TextDecoration.underline : TextDecoration.none,
      ),
    );
  }
}
