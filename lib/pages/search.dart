import 'package:flutter/material.dart';
import 'package:klang/page_container.dart';
import 'package:klang/pages/klang_page.dart';

class SearchPage extends StatelessWidget implements KlangPage {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("search page"),
    );
  }

  @override
  PageRoutePath get route => PageRoutePath.search(null, null);
}
