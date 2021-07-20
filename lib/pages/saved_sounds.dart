import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klang/constants/klang_constants.dart';
import 'package:klang/http_helper.dart';
import 'package:klang/klang_obj_list.dart';
import 'package:klang/klang_obj_list_items.dart';
import 'package:klang/main.dart';
import 'package:klang/objects/klang_sound.dart';
import 'package:klang/page_router.dart';
import 'package:klang/pages/error.dart';
import 'package:klang/pages/klang_page.dart';
import 'package:klang/presets.dart';

class SavedSoundsPage extends StatefulWidget implements KlangPage {
  SavedSoundsPage({this.uid});
  final String uid;

  @override
  State<StatefulWidget> createState() {
    return _SavedSoundsPageState();
  }

  @override
  PageRoutePath get route => PageRoutePath.savedSounds(uid);
}

class _SavedSoundsPageState extends State<SavedSoundsPage> {
  // StreamController savedController;
  String _metric;
  Map<String, int> _listIndices;
  int _nextListIndx;
  List<Widget> _lists;

  @override
  void initState() {
    super.initState();
    // savedController = StreamController();
    // savedController.sink.addStream(_getSavedSounds().asStream());
    // # cache _metric and get last used one
    _metric = Metrics.best;
    _listIndices = {};
    _nextListIndx = 0;
    _lists = [];
    // GetSavedItems
    // .type_saved_items_timestamp_saved; // # check if user preferences saved, if yes, then load based on that
  }

  @override
  void dispose() {
    super.dispose();
    // savedController.close();
  }

  @override
  Widget build(BuildContext context) {
    // if not list owner
    if (BlocProvider.of<AuthCubit>(context).uid != widget.uid)
      return Center(child: Text("users can only view their own saved sounds"));

    // # add lastItemMessage to id list to show custom message for each list, ex: "no more saved sounds", instead of only "no more items for now"
    final user = BlocProvider.of<AuthCubit>(context).state;
    // if saved items not loaded, show error page, temporary while setup load ids when ready
    if (!user.savedItemsReady) {
      return Scaffold(
        appBar: AppBar(
          title: Text("saved sounds"),
        ),
        body: ErrorPage(onHandleError: () {
          setState(() {});
        }),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("saved sounds"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: KlangPadding.def),
            child: DropdownButton<String>(
              value: _metric,
              items: [
                GetSavedItems.type_saved_items_timestamp_saved,
                Metrics.best,
                Metrics.downloads,
                Metrics.saves,
              ]
                  .map(
                    (val) => DropdownMenuItem(
                      value: val,
                      child: Text(_metricCodeToMsg(val)),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (_metric == val) return;
                setState(() {
                  _metric = val;
                  debugPrint(
                      "***changed metric, new metric: ${_metricCodeToMsg(_metric)}");
                });
              },
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _getSelectedListIndx(user),
              children: _lists,
            ),
          ),
        ],
      ),
    );
  }

  int _getSelectedListIndx(UserState user) {
    if (_listIndices[_metric] == null) {
      _listIndices[_metric] = _nextListIndx++;
      setState(() {
        _lists.add(
          _metric == GetSavedItems.type_saved_items_timestamp_saved
              ? KlangItemIdList(
                  ids: user.soundIdsTSDesc(),
                  loadObjs: (ids) async {
                    final r = await FirePP.saved_items<KlangSound>(
                      metric: _metric,
                      itemIds: user.soundIdsTSDesc(),
                    );
                    if (r.resultMsg != SavedItemsResultMsg.success) {
                      debugPrint(
                          "**FirePP.search_sounds_home failed, resultMsg: ${r.resultMsg}");
                      throw FirePP.translateSavedItemsResultMsg(r.resultMsg);
                    }
                    return r.items;
                  },
                  buildItem: (s) => SoundListItem(sound: s),
                  buildLoadingItem: () => LoadingListItem(),
                  buildFailedToLoadItem: (msg, onRetry) =>
                      RetryLoadingListItem(msg: msg, onRetry: onRetry),
                )
              : KlangItemList<KlangSound, KlangListItem>(
                  loadMore: (offset) async {
                    final r = await FirePP.saved_items<KlangSound>(
                      metric: _metric,
                      offset: offset,
                    );
                    if (r.resultMsg != SavedItemsResultMsg.success) {
                      debugPrint(
                          "**FirePP.search_sounds_home failed, resultMsg: ${r.resultMsg}");
                      throw FirePP.translateSavedItemsResultMsg(r.resultMsg);
                    }
                    return r.items;
                  },
                  buildItem: (s) => SoundListItem(sound: s),
                  buildLoadingItem: () => LoadingListItem(),
                  buildFailedToLoadItem: (msg, onRetry) =>
                      RetryLoadingListItem(msg: msg, onRetry: onRetry),
                  queryOffset: (s) => s.getSavedQueryOffset(_metric),
                ),
        );
      });
    }
    return _listIndices[_metric];
  }

  String _metricCodeToMsg(String metricCode) {
    switch (metricCode) {
      case Metrics.downloads:
        return "most downloads";
      case Metrics.best:
        return "best";
      case Metrics.saves:
        return "most saves";
      // TODO: need to setup ascending and descending, only changes id order locally, then id list to http funciton
      case GetSavedItems.type_saved_items_timestamp_saved:
      default:
        return "latest saved";
    }
  }
}
