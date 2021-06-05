import 'package:flutter/material.dart';
import 'package:klang/objects/klang_sound.dart';
import 'package:klang/presets.dart';

abstract class KlangListItem extends Widget {
  @required
  KlangListItem({@required KlangSound sound});
}

class HomeSoundListItem extends StatelessWidget implements KlangListItem {
  HomeSoundListItem({@required this.sound});

  final KlangSound sound;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(sound.name),
      trailing: IconButton(
        onPressed: () {
          // TODO: show sound popup menu & options
          // what options? (depend on auth state)
          // if logged in:
          // - save / unsave
          // - ...
          // if logged out:
          // - sign in
          // - ...
          // if logged in or out
          // - download
          // - view creator page
        },
        icon: Icon(Icons.more_vert_rounded),
      ),
    );
  }
}

class SoundLoadingListItem extends StatelessWidget implements KlangListItem {
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

class SoundRetryLoadingListItem extends StatelessWidget
    implements KlangListItem {
  SoundRetryLoadingListItem({@required this.msg, @required this.onRetry});

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
