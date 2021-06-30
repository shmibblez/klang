import 'package:flutter/material.dart';
import 'package:klang/http_helper.dart';
import 'package:klang/objects/klang_user.dart';
import 'package:klang/page_router.dart';
import 'package:klang/pages/klang_page.dart';

class UserPage extends StatelessWidget implements KlangPage {
  UserPage({@required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(uid ?? "profile")),
      body: FutureBuilder(
        future: FirePP.search_item<KlangUser>(itemId: uid),
        builder: (c, snap) {
          return Center(child: Text("profile, uid: $uid"));
        },
      ),
    );
  }

  @override
  PageRoutePath get route => PageRoutePath.user(uid);
}
