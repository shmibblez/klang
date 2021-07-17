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
  String metric;

  @override
  void initState() {
    super.initState();
    // savedController = StreamController();
    // savedController.sink.addStream(_getSavedSounds().asStream());
    metric = GetSavedItems
        .type_saved_items_timestamp_saved; // # check if user preferences saved, if yes, then load based on that
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
    // TODO: add metric picker (most downloads, most saves, timestamp saved)
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
      body: metric == GetSavedItems.type_saved_items_timestamp_saved
          ? KlangItemIdList(
              ids: user.soundIdsTSDesc(),
              loadObjs: (ids) async {
                final r = await FirePP.saved_items<KlangSound>(
                  metric: metric,
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
                  metric: metric,
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
              queryOffset: (s) => s.getSavedQueryOffset(metric),
            ),
    );
  }
}
