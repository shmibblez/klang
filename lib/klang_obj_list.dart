import 'package:flutter/material.dart';
import 'package:klang/klang_obj_list_items.dart';
import 'package:klang/objects/klang_obj.dart';
import 'package:klang/presets.dart';

class KlangItemList<O extends KlangObj, I extends KlangListItem>
    extends StatefulWidget {
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
    @required I extends KlangListItem> extends State<KlangItemList<O, I>> {
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
          if (_sounds.length - i - 1 <= _loadingThreshold &&
              !_failedToLoad &&
              _hasMore &&
              !_loading) {
            Future.delayed(Duration.zero, () async {
              await _loadMore();
            });
          }
          if (i == _sounds.length) {
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

class KlangItemIdList<O extends KlangObj, I extends KlangListItem>
    extends StatefulWidget {
  KlangItemIdList({
    @required this.ids,
    @required this.loadObjs,
    @required this.buildItem,
    @required this.buildLoadingItem,
    @required this.buildFailedToLoadItem,
  });

  final List<String> ids;
  final Future<List<O>> Function(List<String> ids) loadObjs;
  final I Function(O obj) buildItem;
  final I Function() buildLoadingItem;

  /// builds list item that shows [msg] and has button that calls [onRetry] when pressed
  final I Function(
    String msg,
    void Function() onRetry,
  ) buildFailedToLoadItem;

  @override
  State<StatefulWidget> createState() {
    return _KlangItemIdListState();
  }
}

class _KlangItemIdListState<O extends KlangObj, I extends KlangListItem>
    extends State<KlangItemIdList<O, I>> {
  bool _loading;
  bool _hasMore;
  bool _failedToLoad;
  String _failedToLoadMsg;
  // void Function() _delegateListener;
  List<O> _items;
  final int _loadingThreshold = 3;

  @override
  void initState() {
    super.initState();
    _loading = false;
    _hasMore = true;
    _failedToLoad = false;
    _failedToLoadMsg = "";
    _items = [];
    _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        shrinkWrap: true,
        itemBuilder: (_, i) {
          if (_items.length - i - 1 <= _loadingThreshold &&
              !_failedToLoad &&
              _hasMore &&
              !_loading) {
            Future.delayed(Duration.zero, () async {
              await _loadMore();
            });
          }
          if (i == _items.length) {
            if (!_hasMore)
              return Padding(
                padding: KlangPadding.listItemPadding,
                child: Center(
                  child: Text(_items.isEmpty ? "no items" : "no more items"),
                ),
              );
            if (_failedToLoad)
              return widget.buildFailedToLoadItem(_failedToLoadMsg, () {
                _loadMore();
              });
            return widget.buildLoadingItem();
          }

          return widget.buildItem(_items[i]);
        },
        itemCount: _items.length + 1
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
      int start = _items.length == 0 ? 0 : _items.length - 1;
      int end = start + 20;
      if (end >= widget.ids.length) {
        end = widget.ids.length == 0 ? 0 : widget.ids.length - 1;
      }
      if (start == end) {
        // if all ids loaded already
        newSounds = [];
      } else {
        final idsToLoad = widget.ids.getRange(start + 1, end).toList();
        newSounds = await widget.loadObjs(idsToLoad);
      }
    } catch (msg) {
      _failedToLoad = true;
      _failedToLoadMsg = msg.toString();
      newSounds = [];
    }
    setState(() {
      if (!_failedToLoad && newSounds.isEmpty)
        _hasMore = false;
      else
        _items.addAll(newSounds);
      _loading = false;
    });
  }
}
