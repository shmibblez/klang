import 'package:flutter/material.dart';
import 'package:klang/constants/constants.dart';
import 'package:klang/http_helper.dart';
import 'package:klang/list_items/sound_list_items.dart';
import 'package:klang/lists/sound_list.dart';
import 'package:klang/objects/klang_sound.dart';
import 'package:klang/page_router.dart';
import 'package:klang/pages/klang_page.dart';

class SearchResultsPage extends StatefulWidget implements KlangPage {
  SearchResultsPage({@required this.searchStr});

  final String searchStr;

  @override
  PageRoutePath get route => PageRoutePath.search(searchStr);

  @override
  State<StatefulWidget> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  List<Tab> _tabs;
  List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _tabs = [
      Tab(text: "sounds"),
      Tab(text: "users"),
      // Tab(text: "lists"),
    ];
    _pages = [
      KlangItemList<KlangSound, KlangListItem>(
        loadMore: (offset) async {
          final res = await FirePP.search_from_str(
            searchStr: widget.searchStr,
            offset: offset,
          );
          if(res.resultMsg != SearchFromKeysResultMsg.success) {
            throw FirePP.translateSearchSoundHomeResultMsg(res.resultMsg);
          }
        },
      ),
      KlangItemList(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabBar(tabs: _tabs),
      body: TabBarView(children: _pages),
    );
  }
}
