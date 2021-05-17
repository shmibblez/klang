import 'package:flutter/material.dart';
import 'package:klang/page_container.dart';
import 'package:klang/pages/klang_page.dart';

class UnknownPage extends StatelessWidget implements KlangPage {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("unknown url"),
    );
  }

  @override
  PageRoutePath get route => PageRoutePath.unknown();
}
