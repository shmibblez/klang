import 'package:flutter/material.dart';
import 'package:klang/main.dart';
import 'package:klang/page_router.dart';
import 'package:klang/pages/klang_page.dart';

class SearchPage extends StatefulWidget implements KlangPage {
  @override
  State<StatefulWidget> createState() {
    return _SearchPageState();
  }

  @override
  PageRoutePath get route => PageRoutePath.search(null);
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _searchController = TextEditingController();

  bool _searching;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _searching
            ? IconButton(
                onPressed: _searchController.clear, icon: Icon(Icons.close))
            : Container(),
        title: TextField(
          controller: _searchController,
          onTap: () {
            _searching = true;
          },
          onSubmitted: (str) {
            _searching = false;
            _search(str);
          },
        ),
      ),
      body: Container(),
    );
  }

  void _search(String searchStr) {
    NavCubit.pushPath(context, PageRoutePath.search(searchStr));
  }
}
