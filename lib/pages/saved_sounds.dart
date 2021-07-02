import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  void initState() {
    super.initState();
    savedController = StreamController();
    savedController.sink.addStream(_getSavedSounds().asStream());
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
        // TODO: depending on query, get saved sounds
        //
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
}
