import 'package:flutter/material.dart';
import 'package:klang/constants.dart';

class SearchResultsPage extends StatelessWidget {
  SearchResultsPage({@required this.contentType, @required this.searchStr});

  final KlangContentType contentType;
  final String searchStr;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "search page, content type: ${this.contentType}, searchStr: ${this.searchStr}",
      ),
    );
  }
}
