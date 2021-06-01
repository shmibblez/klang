import 'package:flutter/material.dart';

/// file of widgets with presets, so can reuse styles & keep them uniform

// class ErrorText extends Text {
//   ErrorText(String text) : super(text);
// }
class KlangPadding {
  static const EdgeInsetsGeometry formTextFieldPadding = EdgeInsets.all(8.0);
  static const EdgeInsetsGeometry formButtonPadding = EdgeInsets.all(8.0);
  static const EdgeInsetsGeometry formFieldPadding = EdgeInsets.all(8.0);
  static const EdgeInsetsGeometry listItemPadding = EdgeInsets.all(8.0);
}

class SnackBarMessageText extends Text {
  SnackBarMessageText(String text)
      : super(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        );
}

class ErrorSnackbar extends SnackBar {
  ErrorSnackbar(String message)
      : super(
          content: SnackBarMessageText(message),
          duration: Duration(seconds: 5),
          backgroundColor: Colors.red[400],
        );
}

class SuccessSnackbar extends SnackBar {
  SuccessSnackbar(String message)
      : super(
          content: SnackBarMessageText(message),
          duration: Duration(seconds: 5),
          backgroundColor: Colors.green[500],
        );
}

class KlangTextFormField extends StatelessWidget {
  KlangTextFormField(
    this.label, {
    @required this.controller,
    @required this.validator,
    GlobalKey<FormFieldState> key,
    this.trailing,
  }) : this._key = key;

  final String label;
  final TextEditingController controller;
  final String Function(String) validator;
  final Key _key;
  final IconButton trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: KlangPadding.formTextFieldPadding,
      child: TextFormField(
        key: _key,
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: trailing,
        ),
      ),
    );
  }
}

class KlangFormButtonPrimary extends StatelessWidget {
  KlangFormButtonPrimary(
    this.text, {
    @required this.onPressed,
  });

  final String text;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: KlangPadding.formButtonPadding,
      child: ElevatedButton(onPressed: onPressed, child: Text(text)),
    );
  }
}

class KlangFormButtonSecondary extends StatelessWidget {
  KlangFormButtonSecondary(
    this.text, {
    @required this.onPressed,
  });

  final String text;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: KlangPadding.formButtonPadding,
      child: OutlinedButton(onPressed: onPressed, child: Text(text)),
    );
  }
}
