import 'package:flutter/material.dart';
import 'package:klang/page_router.dart';
import 'package:klang/pages/klang_page.dart';

class UserPage extends StatelessWidget implements KlangPage {
  UserPage({this.showAppBar = true, @required this.uid});

  final bool showAppBar;
  final String uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(uid ?? "profile"),
            )
          : null,
      body: Center(
        child: Text("user page"),
      ),
    );
  }

  @override
  PageRoutePath get route => PageRoutePath.user(uid);
}
