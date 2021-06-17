import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

// TODO: make sound background show progress, also fix progress listeners (closing wrong stream, not listening sometimes)
class _SoundListItemState extends State<SoundListItem> {
  StreamSubscription<Duration> _onProgressStreamSub;
  StreamSubscription<String> _onPlayingSoundIdStreamSub;
  bool _playing;
  double _progress; // percent of playing completion (from 0 to 1)

  @override
  void initState() {
    super.initState();
    _playing = false;
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
        ListTile(
          title: Text(widget.sound.name + ", progress: $_progress"),
          onTap: _onTapSound,
          trailing: PopupMenuButton<_SoundMenuOption>(
            child: Icon(Icons.more_vert_rounded),
            itemBuilder: _buildMenuOptions,
            onSelected: (op) {
              switch (op) {
                case _SoundMenuOption.log_in:
                  NavCubit.pushPath(context, PageRoutePath.login());
                  break;
                case _SoundMenuOption.change_saved:
                  final id = widget.sound.id; // id of sound to save
                  // TODO send save/unsave request to db (if loading disable option and show "loading..."), if success update local list, if error notify user "failed to save"
                  // while loading, show saving with loading icon after sound name (set state _loading = true, and for title show row with sound name and saving/unsaving icon with circular progress indicator)
                  break;
                case _SoundMenuOption.visit_creator:
                  NavCubit.pushPath(
                      context, PageRoutePath.user(widget.sound.creator_id));
                  break;
                case _SoundMenuOption.download:
                  // TODO
                  // - check permissions
                  // - download and save to path
                  break;
              }
            },
          ),
        ),
      ],
    );
  }

  void _onTapSound() async {
    DJCubit cube = BlocProvider.of<DJCubit>(context);
    await cube.play(widget.sound);

    setState(() {
      _playing = true;
    });
    _onProgressStreamSub?.cancel();
    _onProgressStreamSub = cube.onProgress().listen((progress) {
      setState(() {
        _progress = progress.inSeconds / widget.sound.audio_file_duration;
      });
    });

    // if playing sound id isn't this one, that means it changed, cancel onProgress stream and set [_playing] to false
    _onPlayingSoundIdStreamSub ??= cube.onPlayingId().listen((playingId) {
      if (_playing && playingId != widget.sound.id) {
        setState(() {
          _playing = false;
        });
        _onProgressStreamSub?.cancel();
      }
    });
  }

  List<PopupMenuEntry<_SoundMenuOption>> _buildMenuOptions(BuildContext c) {
    //     // TODO: show sound popup menu & options
    //     // what options? (depend on auth state)
    //     // if logged in:
    //     // - save / unsave
    //     // - ...
    //     // if logged out:
    //     // - sign in
    //     // - ...
    //     // if logged in or out
    //     // - download
    //     // - view creator page
    AuthCubit ac = BlocProvider.of<AuthCubit>(c);
    return <PopupMenuEntry<_SoundMenuOption>>[
      if (!ac.loggedIn)
        PopupMenuItem(
          value: _SoundMenuOption.log_in,
          child: Text("log in"),
        ),
      // for saved sounds could have saved sounds cubit that loads saved items. If not ready, show "save/unsave" greyed out, if already loaded, then check and show corresponding "save" or "unsave"
      if (ac.loggedIn)
        PopupMenuItem(
          value: _SoundMenuOption.log_in,
          child: Text("save / unsave"),
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

class UserListItem extends StatelessWidget implements KlangListItem {
  UserListItem({@required this.user});

  final KlangUser user;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.account_box_rounded),
      title: Text(user.name),
      trailing: IconButton(
        onPressed: () {
          // TODO: show user popup menu & options
          // what options? (depend on auth state)
          // if logged out:
          // - sign in
          // - ...
          // if logged in or out
          // - view user's profile
        },
        icon: Icon(Icons.more_vert_rounded),
      ),
    );
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
