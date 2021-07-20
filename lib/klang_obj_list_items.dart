import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klang/http_helper.dart';
import 'package:klang/main.dart';
import 'package:klang/objects/klang_sound.dart';
import 'package:klang/objects/klang_user.dart';
import 'package:klang/page_router.dart';
import 'package:klang/presets.dart';

abstract class KlangListItem extends Widget {
  @required
  KlangListItem({@required KlangSound sound});
}

enum _SoundMenuOption { log_in, change_saved, visit_creator, download }

class SoundListItem extends StatefulWidget implements KlangListItem {
  SoundListItem({@required this.sound});

  final KlangSound sound;

  @override
  State<StatefulWidget> createState() {
    return _SoundListItemState();
  }
}

class _SoundListItemState extends State<SoundListItem> {
  StreamSubscription<Duration> _onProgressStreamSub;
  StreamSubscription<String> _onPlayingSoundIdStreamSub;
  bool _active;
  double _progress; // percent of playing completion (from 0 to 1)
  Size _size;

  @override
  void initState() {
    super.initState();
    _active = false;
    _progress = 0;
    // if sound currently playing, then setup listeners and show progress.
    // Doesn't update progress if sound list item already built (would require
    // all sound list items to always have listeners active)
    DJCubit cube = BlocProvider.of<DJCubit>(context);
    if (cube.state == widget.sound.id) {
      _active = true;
      _setupListeners(cube);
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _size = context.size;
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (_onProgressStreamSub != null) _onProgressStreamSub.cancel();
    if (_onPlayingSoundIdStreamSub != null) _onPlayingSoundIdStreamSub.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_active && _size != null)
          Container(
            height: _size.height,
            width: _size.width * _progress,
            color: Colors.green[200],
          ),
        ListTile(
          title: Text(widget.sound.name),
          onTap: _onTapSound,
          trailing: PopupMenuButton<_SoundMenuOption>(
            child: Icon(Icons.more_vert_rounded),
            itemBuilder: _buildMenuOptions,
            onSelected: (op) async {
              switch (op) {
                case _SoundMenuOption.log_in:
                  NavCubit.pushPath(context, PageRoutePath.login());
                  break;
                case _SoundMenuOption.change_saved:
                  {
                    AuthCubit ac = BlocProvider.of<AuthCubit>(context);
                    bool isSaved =
                        ac.loggedIn && ac.state.isSoundSaved(widget.sound.id);
                    ac.setSoundPendingSaveState(widget.sound.id);
                    debugPrint("***isSaved: $isSaved");
                    if (isSaved) {
                      try {
                        UnsaveSoundResultMsg r =
                            await FirePP.unsave_sound(widget.sound.id);
                        if (r == UnsaveSoundResultMsg.success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SuccessSnackbar("unsaved sound successfully"));
                          ac.state.notifySoundUnsaved(widget.sound.id);
                        } else {
                          throw r;
                        }
                      } catch (e) {
                        ac.setSoundNotPendingSaveState(widget.sound.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                            ErrorSnackbar(e is SaveSoundResultMsg
                                ? FirePP.translateSaveSoundResultMsg(e)
                                : e.toString()));
                      }
                    } else {
                      try {
                        SaveSoundResultMsg r =
                            await FirePP.save_sound(widget.sound.id);
                        if (r == SaveSoundResultMsg.success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SuccessSnackbar("saved sound successfully"));
                          ac.state.notifySoundSaved(widget.sound.id);
                        } else {
                          throw r;
                        }
                      } catch (e) {
                        ac.setSoundNotPendingSaveState(widget.sound.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                            ErrorSnackbar(e is SaveSoundResultMsg
                                ? FirePP.translateSaveSoundResultMsg(e)
                                : e.toString()));
                      }
                    }
                    ac.setSoundNotPendingSaveState(widget.sound.id);
                  }
                  break;
                case _SoundMenuOption.visit_creator:
                  NavCubit.pushPath(
                      context, PageRoutePath.user(widget.sound.creator_id));
                  break;
                case _SoundMenuOption.download:
                  ScaffoldMessenger.of(context).showSnackBar(
                      ErrorSnackbar("download sound when option selected"));
                  break;
              }
            },
          ),
        ),
      ],
    );
  }

  void _onTapSound() async {
    setState(() {
      _active = true;
    });
    DJCubit cube = BlocProvider.of<DJCubit>(context);
    _setupListeners(cube);
  }

  void _setupListeners(DJCubit cube) {
    _onProgressStreamSub ??= cube.onProgress().listen((pos) {
      setState(() {
        _progress =
            pos?.inMilliseconds ?? 0 / cube.soundDuration?.inMilliseconds ?? 0;
        if (_progress >= 1) _progress = 0;
      });
    });

    // if playing sound id isn't this one, that means it changed, cancel onProgress stream and set [_playing] to false
    _onPlayingSoundIdStreamSub ??= cube.stream.listen((activeSoundId) {
      if (activeSoundId != widget.sound.id) {
        setState(() {
          _active = false;
          _progress = 0;
        });
        _onProgressStreamSub.cancel();
        _onPlayingSoundIdStreamSub?.cancel();
        _onProgressStreamSub = null;
        _onPlayingSoundIdStreamSub = null;
      }
    });
  }

  List<PopupMenuEntry<_SoundMenuOption>> _buildMenuOptions(BuildContext c) {
    // TODO: some options not working (ex: "download")
    AuthCubit ac = BlocProvider.of<AuthCubit>(c);
    bool isSaved = ac.loggedIn && ac.state.isSoundSaved(widget.sound.id);
    bool isPendingSaveState =
        ac.loggedIn && ac.isSoundPendingSaveState(widget.sound.id);
    debugPrint("&&&isSaved: $isSaved, isPendingSaveState: $isPendingSaveState");
    return <PopupMenuEntry<_SoundMenuOption>>[
      if (!ac.loggedIn)
        PopupMenuItem(
          value: _SoundMenuOption.log_in,
          child: Text("log in to save"),
        ),
      // for saved sounds could have saved sounds cubit that loads saved items. If not ready, show "save/unsave" greyed out, if already loaded, then check and show corresponding "save" or "unsave"
      if (ac.loggedIn)
        PopupMenuItem(
          enabled:
              ac.loggedIn && ac.state.savedItemsReady && !isPendingSaveState,
          value: _SoundMenuOption.change_saved,
          child: isPendingSaveState
              ? Text(isSaved ? "unsaving..." : "saving...")
              : ac.loggedIn && ac.state.savedItemsReady
                  ? Text(isSaved ? "unsave" : "save")
                  : Text("save / unsave loading..."),
        ),
      // push new route to
      PopupMenuItem(
        value: _SoundMenuOption.visit_creator,
        child: Text("visit creator"),
      ),
      // need to check permissions, then ask user to select what folder they want to download to (could edit in settings). Could just set default folder for initial release
      PopupMenuItem(
        value: _SoundMenuOption.download,
        child: Text("download"),
      ),
    ];
  }
}

// TODO: any other options?
enum _UserMenuOption { visit }

class UserListItem extends StatefulWidget implements KlangListItem {
  UserListItem({@required this.user});

  final KlangUser user;

  @override
  State<StatefulWidget> createState() => _UserListItemState();
}

class _UserListItemState extends State<UserListItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.account_box_rounded),
      title: Text(widget.user.name),
      trailing: PopupMenuButton<_UserMenuOption>(
        child: Icon(Icons.more_vert_rounded),
        itemBuilder: _buildMenuOptions,
        onSelected: (op) async {
          switch (op) {
            // case _UserMenuOption.log_in:
            //   NavCubit.pushPath(context, PageRoutePath.login());
            //   break;

            case _UserMenuOption.visit:
              NavCubit.pushPath(context, PageRoutePath.user(widget.user.id));
              break;
          }
        },
      ),
    );
  }

  List<PopupMenuEntry<_UserMenuOption>> _buildMenuOptions(BuildContext c) {
    // AuthCubit ac = BlocProvider.of<AuthCubit>(c);
    return <PopupMenuEntry<_UserMenuOption>>[
      // // if logged out
      // if (!ac.loggedIn)
      //   PopupMenuItem(
      //     value: _UserMenuOption.log_in,
      //     child: Text("log in to follow"),
      //   ),
      // // if logged in
      // if (ac.loggedIn)
      //   PopupMenuItem(
      //     enabled:
      //         ac.loggedIn && ac.state.savedItemsReady && !isPendingSaveState,
      //     value: _SoundMenuOption.change_saved,
      //     child: isPendingSaveState
      //         ? Text(isSaved ? "unsaving..." : "saving...")
      //         : ac.loggedIn && ac.state.savedItemsReady
      //             ? Text(isSaved ? "unsave" : "save")
      //             : Text("save / unsave loading..."),
      //   ),
      // push new route to
      PopupMenuItem(
        value: _UserMenuOption.visit,
        child: Text("visit user"),
      ),
    ];
  }
}

class LoadingListItem extends StatelessWidget implements KlangListItem {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: KlangPadding.listItemPadding,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class RetryLoadingListItem extends StatelessWidget implements KlangListItem {
  RetryLoadingListItem({@required this.msg, @required this.onRetry});

  final String msg;
  final void Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.red[400],
      contentPadding: KlangPadding.listItemPadding,
      title: ErrorText(msg),
      trailing: OutlinedButton(
        child: ErrorText("retry?"),
        onPressed: onRetry,
      ),
    );
  }
}
