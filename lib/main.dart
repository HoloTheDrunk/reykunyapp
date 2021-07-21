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
      theme: ThemeData.dark(),
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
    return Container(
      child: Column(
        children: [
          Text(queryResult.navi.text),
          Text(queryResult.translation.text),
          for (int i = 0; i < (queryResult.affixes?.length ?? 0); i += 2)
            Text(
                '${queryResult.affixes![i].text}: ${queryResult.affixes![i + 1].text}'),
        ],
      ),
    );
  }
}
