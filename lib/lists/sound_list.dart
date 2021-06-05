import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klang/list_items/sound_list_items.dart';
import 'package:klang/objects/klang_sound.dart';
import 'package:klang/presets.dart';

class SoundList extends StatefulWidget {
  SoundList({
    @required this.loadMore,
    @required this.buildItem,
    @required this.buildLoadingItem,
    @required this.buildFailedToLoadItem,
    @required this.queryOffset,
  });

  final Future<List<KlangSound>> Function(List offset) loadMore;
  final SoundListItem Function(KlangSound sound) buildItem;
  final SoundListItem Function() buildLoadingItem;

  /// builds list item that shows [msg] and has button that calls [onRetry] when pressed
  final SoundListItem Function(
    String msg,
    void Function() onRetry,
  ) buildFailedToLoadItem;
  final List<String> Function(KlangSound) queryOffset;

  @override
  State<StatefulWidget> createState() {
    return _SoundListState();
  }
}

enum _SoundListEvent { loading, newSounds, error, noMore }

class _SoundListState extends State<SoundList> {
  bool _loading;
  bool _hasMore;
  bool _failedToLoad;
  String _failedToLoadMsg;
  // void Function() _delegateListener;
  List<KlangSound> _sounds;
  final int _loadingThreshold = 3;
  StreamController<_SoundListEvent> _eventStream;

  @override
  void initState() {
    super.initState();
    _loading = false;
    _hasMore = true;
    _failedToLoad = false;
    _failedToLoadMsg = "";
    _sounds = [];
    _eventStream = StreamController();
    _loadMore();
  }

  @override
  void dispose() {
    super.dispose();
    _eventStream.close();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        shrinkWrap: true,
        itemBuilder: (_, i) {
          if (_sounds.length - i - 1 == _loadingThreshold &&
              _hasMore &&
              !_loading) {
            _loadMore();
          }
          if (i == _sounds.length) {
            if (!_hasMore)
              return Padding(
                padding: KlangPadding.listItemPadding,
                child: Center(child: Text("no more items")),
              );
            return StreamBuilder<_SoundListEvent>(
                stream: _eventStream.stream,
                builder: (_, snap) {
                  debugPrint("***streamBuilder event, snap.data: ${snap.data}");
                  if (snap.data == _SoundListEvent.error) {
                    return widget.buildFailedToLoadItem(_failedToLoadMsg, () {
                      _loadMore();
                    });
                  } else if (snap.data == _SoundListEvent.newSounds) {
                    Future.delayed(Duration.zero, () {
                      setState(() {});
                    });
                    return widget.buildItem(_sounds[i]);
                  } else {
                    return widget.buildLoadingItem();
                  }
                });
          }
          return widget.buildItem(_sounds[i]);
        },
        itemCount: _sounds.length + 1
        // _loading || _failedToLoad || !_hasMore
        //     ? _sounds.length + 1
        //     : _sounds.length, // widget.delegate.itemCount,
        );
  }

  void _loadMore() async {
    if (_failedToLoad) _failedToLoad = false;
    if (_loading) return;
    // setState(() {
    //   _loading = true;
    // });
    _loading = true;
    _eventStream.add(_SoundListEvent.loading);

    List<KlangSound> newSounds;
    try {
      newSounds = await widget
          .loadMore(_sounds.isEmpty ? null : widget.queryOffset(_sounds.last));
    } catch (msg) {
      _failedToLoad = true;
      _failedToLoadMsg = msg.toString();
      newSounds = [];
    }

    // setState(() {
    //   if (!_failedToLoad && newSounds.isEmpty)
    //     _hasMore = false;
    //   else
    //     _sounds.addAll(newSounds);
    //   _loading = false;
    // });

    if (!_failedToLoad && newSounds.isEmpty) {
      _hasMore = false;
      _eventStream.add(_SoundListEvent.noMore);
    } else {
      _sounds.addAll(newSounds);
      _eventStream.add(_SoundListEvent.newSounds);
    }

    _loading = false;
  }
}

// TODO: don't need delegate, all SoundList needs is
// - buildItem
// - buildLoadingItem
// - loadMore (callback function to load more sounds, should be async, show loading item while loads)
// only other thing is, how to handle error? could have failed to load list item, and if failed to load, retry loading when retry pressed

// and thats it, some other important stuff:
// - need to have loading threshold: if within last 3 items, load more sounds
