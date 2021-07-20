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
  // ignore: unused_field, in case use it in future
  bool _searching;
  FocusNode _searchFocusNode;
  TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searching = false;
    _searchFocusNode = FocusNode();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            _searchController.clear();
            setState(() {
              _searchFocusNode.requestFocus();
              _searching = true;
            });
          },
          icon: Icon(Icons.close),
        ),
        title: TextField(
          style: TextStyle(color: Colors.white),
          autofocus: true,
          focusNode: _searchFocusNode,
          showCursor: true,
          cursorColor: Colors.white,
          controller: _searchController,
          onTap: () {
            setState(() {
              _searching = true;
            });
          },
          onSubmitted: (str) {
            setState(() {
              _searching = false;
            });
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
