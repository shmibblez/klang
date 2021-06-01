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
  });

  final Future<List<KlangSound>> Function(List offset) loadMore;
  final SoundListItem Function(KlangSound sound) buildItem;
  final SoundListItem Function() buildLoadingItem;

  /// builds list item that shows [msg] and has button that calls [onRetry] when pressed
  final SoundListItem Function(
    String msg,
    void Function() onRetry,
  ) buildFailedToLoadItem;

  @override
  State<StatefulWidget> createState() {
    return _SoundListState();
  }
}

class _SoundListState extends State<SoundList> {
  bool _loading;
  bool _hasMore;
  bool _failedToLoad;
  String _failedToLoadMsg;
  // void Function() _delegateListener;
  List<KlangSound> _sounds;
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
        if (i == _sounds.length) {
          if (_loading) return widget.buildLoadingItem();
          if (_failedToLoad)
            return widget.buildFailedToLoadItem(_failedToLoadMsg, () {
              setState(() {
                _failedToLoad = false;
                _loadMore();
              });
            });
          if (!_hasMore)
            return Padding(
              padding: KlangPadding.listItemPadding,
              child: Center(
                  child: Text(_sounds.isEmpty ? "no items" : "no more items")),
            );
        }
        if (_hasMore &&
            !_loading &&
            _sounds.length - i - 1 == _loadingThreshold) {
          _loadMore();
        }
        return widget.buildItem(_sounds[i]);
      },
      itemCount: _loading || _failedToLoad || !_hasMore
          ? _sounds.length + 1
          : _sounds.length, // widget.delegate.itemCount,
    );
  }

  void _loadMore() async {
    if (_failedToLoad) _failedToLoad = false;
    if (_loading) return;
    _loading = true;
    List<KlangSound> newSounds;
    try {
      newSounds = await widget
          // TODO: setup offset
          // need to include time period values for metrics in FieldMasks
          .loadMore(_sounds.isEmpty ? null : [_sounds.last.creator_id]);
    } catch (msg) {
      _failedToLoad = true;
      _failedToLoadMsg = msg.toString();
      newSounds = [];
    }
    setState(() {
      if (newSounds.isEmpty)
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
