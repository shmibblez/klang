import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klang/http_helper.dart';
import 'package:klang/klang_obj_list.dart';
import 'package:klang/klang_obj_list_items.dart';
import 'package:klang/main.dart';
import 'package:klang/objects/klang_sound.dart';
import 'package:klang/page_router.dart';
import 'package:klang/pages/klang_page.dart';

class SavedSoundsPage extends StatefulWidget implements KlangPage {
  SavedSoundsPage({this.uid});
  final String uid;

  @override
  State<StatefulWidget> createState() {
    return _SavedSoundsPageState();
  }

  @override
  PageRoutePath get route => throw UnimplementedError();
}

class _SavedSoundsPageState extends State<SavedSoundsPage> {
  StreamController savedController;
  String metric;

  @override
  void initState() {
    super.initState();
    savedController = StreamController();
    savedController.sink.addStream(_getSavedSounds().asStream());
    metric =
        "tims"; // # check if user preferences saved, if yes, then load based on that
  }

  @override
  void dispose() {
    super.dispose();
    savedController.close();
  }

  @override
  Widget build(BuildContext context) {
    // if not list owner
    if (BlocProvider.of<AuthCubit>(context).uid != widget.uid)
      return Center(child: Text("users can only view their own saved sounds"));
    // if list owner, get saved sounds
    return StreamBuilder(
      stream: savedController.stream,
      builder: (c, snap) {
        // TODO: depending on sounds, build page
        switch (snap.connectionState) {
          case ConnectionState.active:
          case ConnectionState.done:
            return _buildPage();
          case ConnectionState.none:
          case ConnectionState.waiting:
            return CircularProgressIndicator();
        }
        return null;
      },
    );
  }

  Future<List<KlangSound>> _getSavedSounds() {
    // TODO: get saved sounds based on query (local params)
    // - if query is ordered by timestamp saved:
    //   - get saved sounds locally, ordered by timestamp (increasing or decreasing based on local params)
    //   - if not loaded yet, wait to load (need to setup I think)
    // - if query is ordered by metric
    //   - get saved sounds from http function from local params -> this will be clone query with fieldMask to not get whole clone uid list
  }

  Widget _buildPage() {
    // TODO: add metric picker (most downloads, most saves, timestamp saved)
    return Scaffold(
      appBar: AppBar(
        title: Text("saved sounds"),
      ),
      // // TODO: only for clone query, need to make KlangItemIdList that loads items from ids -> add entry to search http function that uses getAll and applies fieldMask
      body: metric == "tims"
          ? KlangItemIdList()
          : KlangItemList<KlangSound, KlangListItem>(
              loadMore: (offset) async {
                final r = await FirePP.saved_items<KlangSound>(
                  itemId: widget.uid,
                  metric: "tims",
                  offset: offset,
                );
                return r.items;
              },
              buildItem: (s) => SoundListItem(sound: s),
              buildLoadingItem: () => LoadingListItem(),
              buildFailedToLoadItem: (msg, onRetry) =>
                  RetryLoadingListItem(msg: msg, onRetry: onRetry),
              queryOffset: (s) => s.getSavedQueryOffset(metric),
            ),
    );
  }
}
