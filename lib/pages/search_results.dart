import 'package:flutter/material.dart';
import 'package:klang/http_helper.dart';
import 'package:klang/klang_obj_list_items.dart';
import 'package:klang/klang_obj_list.dart';
import 'package:klang/objects/klang_sound.dart';
import 'package:klang/objects/klang_user.dart';
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
        queryOffset: (sound) => sound.getSKQueryOffset(),
        loadMore: (offset) async {
          final res = await FirePP.search_from_str<KlangSound>(
            searchStr: widget.searchStr,
            offset: offset,
          );
          if (res.resultMsg != SearchFromKeysResultMsg.success) {
            throw FirePP.translateSearchFromKeysResultMsg(res.resultMsg);
          }
          return res.items;
        },
        buildItem: (sound) => SoundListItem(sound: sound),
        buildLoadingItem: () => LoadingListItem(),
        buildFailedToLoadItem: (msg, onRetry) => RetryLoadingListItem(
          msg: msg,
          onRetry: onRetry,
        ),
      ),
      // FIXME: error in offset, for some reason is empty array with null: [null]
      KlangItemList<KlangUser, KlangListItem>(
        queryOffset: (user) => user.getSKQueryOffset(),
        loadMore: (offset) async {
          final res = await FirePP.search_from_str<KlangUser>(
            searchStr: widget.searchStr,
            offset: offset,
          );
          if (res.resultMsg != SearchFromKeysResultMsg.success) {
            throw FirePP.translateSearchFromKeysResultMsg(res.resultMsg);
          }
          return res.items;
        },
        buildItem: (user) => UserListItem(user: user),
        buildLoadingItem: () => LoadingListItem(),
        buildFailedToLoadItem: (msg, onRetry) => RetryLoadingListItem(
          msg: msg,
          onRetry: onRetry,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(title: TabBar(tabs: _tabs)),
        body: TabBarView(children: _pages),
      ),
    );
  }
}
