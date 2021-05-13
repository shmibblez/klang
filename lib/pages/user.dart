import 'package:flutter/material.dart';

// TODO: if uid is null then either show current user's profile, or sign in / sign up
class UserPage extends StatelessWidget {
  UserPage({@required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("user page"),
    );
  }
}
