import 'package:flutter/material.dart';

class ErrorPage extends StatelessWidget {
  ErrorPage({@required this.onHandleError});

  final void Function() onHandleError;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("mission failed"),
          SizedBox(
            height: 8,
          ),
          OutlinedButton(onPressed: onHandleError, child: Text("retry?"))
        ],
      ),
    );
  }
}
