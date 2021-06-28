import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:klang/constants/klang_constants.dart';
import 'package:klang/http_helper.dart';
import 'package:klang/klang_obj_list_items.dart';
import 'package:klang/klang_obj_list.dart';
import 'package:klang/objects/klang_sound.dart';
import 'package:klang/page_router.dart';
import 'package:klang/pages/klang_page.dart';

class HomePage extends StatefulWidget implements KlangPage {
  @override
  PageRoutePath get route => PageRoutePath.main("home");

  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  String _metric;
  String _timePeriod;
  Map<String, Map<String, int>> _listIndices;
  int _nextListIndx;
  List<KlangItemList<KlangSound, KlangListItem>> _lists;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _metric = Metrics.downloads;
    _timePeriod = Metrics.this_week;
    _listIndices = {};
    _nextListIndx = 0;
    _lists = [];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("home"),
        actions: [
          // if in test mode, show button that when pressed, creates sounds for testing
          if (!kReleaseMode)
            IconButton(
              onPressed: () async {
                await TestFirePP.create_test_sounds();
              },
              icon: Icon(Icons.music_note_rounded),
            )
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              DropdownButton<String>(
                value: _metric,
                items: [Metrics.best, Metrics.downloads]
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
                  });
                },
              ),
              DropdownButton<String>(
                value: _timePeriod,
                items: KlangTimePeriods.map(
                  (val) => DropdownMenuItem(
                    value: val,
                    child: Text(_timePeriodToMsg(val)),
                  ),
                ).toList(),
                onChanged: (val) {
                  if (_timePeriod == val) return;
                  setState(() {
                    _timePeriod = val;
                  });
                },
              )
            ],
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
      _listIndices[_metric] = {};
    }
    if (_listIndices[_metric][_timePeriod] == null) {
      _listIndices[_metric][_timePeriod] = _nextListIndx++;
      setState(() {
        _lists.add(KlangItemList<KlangSound, KlangListItem>(
          loadMore: (offset) async {
            final r = await FirePP.search_sounds_home(
                metric: _metric, time: _timePeriod, offset: offset);

            if (r.resultMsg != SearchSoundHomeResultMsg.success) {
              debugPrint(
                  "**FirePP.search_sounds_home failed, resultMsg: ${r.resultMsg}");
              throw FirePP.translateSearchSoundHomeResultMsg(r.resultMsg);
            }
            return r.sounds;
          },
          buildItem: (sound) => SoundListItem(sound: sound),
          buildLoadingItem: () => LoadingListItem(),
          buildFailedToLoadItem: (msg, onRetry) =>
              RetryLoadingListItem(msg: msg, onRetry: onRetry),
          queryOffset: (sound) =>
              sound.getMetricQueryOffset(_metric, _timePeriod),
        ));
      });
    }
    return _listIndices[_metric][_timePeriod];
  }

  String _metricCodeToMsg(String metricCode) {
    switch (metricCode) {
      case Metrics.best:
        return "best";
      case Metrics.downloads:
      default:
        return "downloads";
    }
  }

  String _timePeriodToMsg(String timePeriod) {
    switch (timePeriod) {
      case Metrics.total:
        return "total";
      case Metrics.this_day:
        return "today";
      case Metrics.this_month:
        return "this month";
      case Metrics.this_year:
        return "this year";
      case Metrics.this_decade:
        return "this decade";
      case Metrics.this_century:
        return "this century";
      case Metrics.this_millenium:
        return "this millenium";
      case Metrics.this_week:
      default:
        return "this week";
    }
  }
}
