import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klang/http_helper.dart';
import 'package:klang/loading_pages/loading.dart';
import 'package:klang/main.dart';
import 'package:klang/objects/klang_user.dart';
import 'package:klang/page_router.dart';
import 'package:klang/pages/error.dart';
import 'package:klang/pages/klang_page.dart';

class UserPage extends StatefulWidget implements KlangPage {
  UserPage({@required this.uid});

  final String uid;

  @override
  PageRoutePath get route => PageRoutePath.user(uid);

  @override
  State<StatefulWidget> createState() {
    return _UserPageState();
  }
}

class _UserPageState extends State<UserPage> {
  StreamController<SearchItemResult<KlangUser>> streamController;

  @override
  void initState() {
    super.initState();
    streamController = StreamController();
    streamController.sink.addStream(
        FirePP.search_item<KlangUser>(itemId: widget.uid).asStream());
  }

  @override
  void dispose() {
    super.dispose();
    streamController.close();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SearchItemResult<KlangUser>>(
      stream: streamController.stream,
      builder: (c, snap) {
        switch (snap.connectionState) {
          case ConnectionState.active:
          case ConnectionState.done:
            if (snap.hasError) {
              return Material(
                child: ErrorPage(
                  onHandleError: () {
                    streamController.sink.addStream(
                        FirePP.search_item<KlangUser>(itemId: widget.uid)
                            .asStream());
                  },
                ),
              );
            }
            return _buildPage(snap.data);
          case ConnectionState.none:
          case ConnectionState.waiting:
            return LoadingPage();
        }
      },
    );
  }

  Widget _buildPage(SearchItemResult<KlangUser> data) {
    if (data.item == null)
      return Center(
        child: Material(child: Text("user not found")),
      );
    return Scaffold(
      appBar: AppBar(title: Text(data.item.name)),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              data.item.name,
              textAlign: TextAlign.center,
            ),
            GestureDetector(
              onTap: () {
                NavCubit.pushPath(
                    context,
                    PageRoutePath.savedSounds(
                      BlocProvider.of<AuthCubit>(context).uid,
                    ));
              },
              child: Row(
                children: [
                  Text("saved sounds"),
                  Icon(Icons.chevron_right_sharp),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
