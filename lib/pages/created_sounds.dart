import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klang/constants/klang_constants.dart';
import 'package:klang/http_helper.dart';
import 'package:klang/klang_obj_list.dart';
import 'package:klang/klang_obj_list_items.dart';
import 'package:klang/main.dart';
import 'package:klang/objects/klang_sound.dart';
import 'package:klang/page_router.dart';
import 'package:klang/pages/klang_page.dart';
import 'package:klang/presets.dart';

class CreatedSoundsPage extends StatefulWidget implements KlangPage {
  CreatedSoundsPage({this.uid});
  final String uid;

  @override
  State<StatefulWidget> createState() => _CreatedSoundsPageState();

  @override
  PageRoutePath get route => PageRoutePath.createdSounds(uid);
}

class _CreatedSoundsPageState extends State<CreatedSoundsPage> {
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
    // # add lastItemMessage to id list to show custom message for each list, ex: "no more saved sounds", instead of only "no more items for now"
    return Scaffold(
      appBar: AppBar(
        title: Text("created sounds"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: KlangPadding.def),
            child: DropdownButton<String>(
              value: _metric,
              items: [
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
              index: _getSelectedListIndx(),
              children: _lists,
            ),
          ),
        ],
      ),
    );
  }

  int _getSelectedListIndx() {
    if (_listIndices[_metric] == null) {
      _listIndices[_metric] = _nextListIndx++;
      setState(() {
        _lists.add(
          KlangItemList<KlangSound, KlangListItem>(
            loadMore: (offset) async {
              final r = await FirePP.search_user_created_items<KlangSound>(
                creatorId:
                    widget.uid ?? BlocProvider.of<AuthCubit>(context).uid,
                metric: _metric,
                explicitOk: true, // TODO: get from user explicit prefs
                offset: offset,
              );
              if (r.resultMsg != SearchUserCreatedItemsResultMsg.success) {
                debugPrint(
                    "**FirePP.search_sounds_home failed, resultMsg: ${r.resultMsg}");
                throw FirePP.translateSearchUserCreatedItemsResultMsg(
                    r.resultMsg);
              }
              return r.items;
            },
            buildItem: (s) => SoundListItem(sound: s),
            buildLoadingItem: () => LoadingListItem(),
            buildFailedToLoadItem: (msg, onRetry) =>
                RetryLoadingListItem(msg: msg, onRetry: onRetry),
            queryOffset: (sound) =>
                sound.getMetricQueryOffset(_metric, Metrics.total),
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
      case Metrics.saves:
        return "most saves";
      case Metrics.best:
      default:
        return "best";
    }
  }
}
