import 'package:flutter/material.dart';
import 'package:klang/list_items/sound_list_items.dart';
import 'package:klang/objects/klang_sound.dart';
import 'package:klang/presets.dart';

class KlangItemList<@required O extends KlangObj,
    @required I extends KlangListItem> extends StatefulWidget {
  KlangItemList({
    @required this.loadMore,
    @required this.buildItem,
    @required this.buildLoadingItem,
    @required this.buildFailedToLoadItem,
    @required this.queryOffset,
  });

  final Future<List<O>> Function(List<dynamic> offset) loadMore;
  final I Function(O obj) buildItem;
  final I Function() buildLoadingItem;

  /// builds list item that shows [msg] and has button that calls [onRetry] when pressed
  final I Function(
    String msg,
    void Function() onRetry,
  ) buildFailedToLoadItem;
  final List<dynamic> Function(O) queryOffset;

  @override
  State<StatefulWidget> createState() => _KlangItemListState<O, I>();
}

class _KlangItemListState<@required O extends KlangObj,
    @required I extends KlangListItem> extends State<KlangItemList> {
  bool _loading;
  bool _hasMore;
  bool _failedToLoad;
  String _failedToLoadMsg;
  // void Function() _delegateListener;
  List<O> _sounds;
  final int _loadingThreshold = 3;

  @override
  void initState() {
    super.initState();
    _loading = false;
    _hasMore = true;
    _failedToLoad = false;
    _failedToLoadMsg = "";
    _sounds = [];
    _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        shrinkWrap: true,
        itemBuilder: (_, i) {
          if (!_failedToLoad &&
              _sounds.length - i - 1 == _loadingThreshold &&
              _hasMore &&
              !_loading) {
            Future.delayed(Duration.zero, () async {
              await _loadMore();
            });
          }
          if (i == _sounds.length) {
            // TODO: make last item StreamBuilder, and emit all events to its stream in _loadMore() instead of calling setState()
            if (!_hasMore)
              return Padding(
                padding: KlangPadding.listItemPadding,
                child: Center(
                  child: Text(_sounds.isEmpty ? "no items" : "no more items"),
                ),
              );
            if (_failedToLoad)
              return widget.buildFailedToLoadItem(_failedToLoadMsg, () {
                _loadMore();
              });
            return widget.buildLoadingItem();
          }

          return widget.buildItem(_sounds[i]);
        },
        itemCount: _sounds.length + 1
        // _loading || _failedToLoad || !_hasMore
        //     ? _sounds.length + 1
        //     : _sounds.length, // widget.delegate.itemCount,
        );
  }

  Future<void> _loadMore() async {
    if (_failedToLoad) _failedToLoad = false;
    if (_loading) return;
    setState(() {
      _loading = true;
    });
    List<O> newSounds;
    try {
      newSounds = await widget
          .loadMore(_sounds.isEmpty ? null : widget.queryOffset(_sounds.last));
    } catch (msg) {
      _failedToLoad = true;
      _failedToLoadMsg = msg.toString();
      newSounds = [];
    }
    setState(() {
      if (!_failedToLoad && newSounds.isEmpty)
        _hasMore = false;
      else
        _sounds.addAll(newSounds);
      _loading = false;
    });
  }
}

// TODO: don't need delegate, all SoundList needs is
// - buildItem
// - buildLoadingItem
// - loadMore (callback function to load more sounds, should be async, show loading item while loads)
// only other thing is, how to handle error? could have failed to load list item, and if failed to load, retry loading when retry pressed

// and thats it, some other important stuff:
// - need to have loading threshold: if within last 3 items, load more sounds
