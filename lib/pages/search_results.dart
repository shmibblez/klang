import 'package:flutter/material.dart';
import 'package:klang/constants.dart';
import 'package:klang/page_router.dart';
import 'package:klang/pages/klang_page.dart';

class SearchResultsPage extends StatelessWidget implements KlangPage {
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

  @override
  PageRoutePath get route => PageRoutePath.search(contentType, searchStr);
}
