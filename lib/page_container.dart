// since all page containers will need same routes, only need 1
// only exception is settings page container, that one will have special paths
import 'package:flutter/material.dart';

// determines page to show as first page
enum DefaultPage { home, search, add, shuffle, profile }

class PageContainer extends StatelessWidget {
  PageContainer({@required this.defaultPage});

  final DefaultPage defaultPage;

  @override
  Widget build(BuildContext context) {
    // TODO: create navigator here & return child page depending on default
    // remember all children need to have provider as child, how to do that?
    return Center(
      child: Text("$defaultPage"),
    );
  }
}
