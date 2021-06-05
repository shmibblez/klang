import 'package:flutter/material.dart';
import 'package:klang/page_router.dart';
import 'package:klang/pages/klang_page.dart';

class UserPage extends StatelessWidget implements KlangPage {
  UserPage({@required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(uid ?? "profile")),
      body: Center(
        child: Text("user page"),
      ),
    );
  }

  @override
  PageRoutePath get route => PageRoutePath.user(uid);
}
