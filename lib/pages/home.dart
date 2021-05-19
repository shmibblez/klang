import 'package:flutter/material.dart';
import 'package:klang/page_router.dart';
import 'package:klang/pages/klang_page.dart';

class HomePage extends StatelessWidget implements KlangPage {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("home page"),
    );
  }

  @override
  PageRoutePath get route => PageRoutePath.main("home");
}
