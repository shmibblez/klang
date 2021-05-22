import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klang/constants/regex.dart';
import 'package:klang/constants/transpiled_constants.dart';
import 'package:klang/http_helper.dart';
import 'package:klang/main.dart';
import 'package:klang/page_router.dart';
import 'package:klang/pages/klang_page.dart';
import 'package:klang/presets.dart';

class CreateAccountPage extends StatefulWidget implements KlangPage {
  @override
  State<StatefulWidget> createState() {
    return _CreateAccountPageState();
  }

  @override
  PageRoutePath get route => PageRoutePath.createAccount();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confEmailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _pswdController = TextEditingController();
  final TextEditingController _confirmPswdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("create account"),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // email
              KlangTextFormField(
                "email",
                controller: _emailController,
                validator: (email) {
                  if (email == null || email.length <= 0) {
                    return "please enter email";
                  }
                  if (!KlangRegex.email.hasMatch(email)) {
                    return "invalid email, need to check for typos";
                  }
                  return null;
                },
              ),
              // email confirmation
              KlangTextFormField(
                "confirm email",
                controller: _confEmailController,
                validator: (emailConf) {
                  if (emailConf != _emailController.text) {
                    return "emails must match";
                  }
                  return null;
                },
              ),
              // username
              KlangTextFormField(
                "username",
                controller: _usernameController,
                validator: (username) {
                  if (username != null || username.length > 0) {
                    if (username.length < Lengths.min_username_length)
                      return "too short, min length is ${Lengths.min_username_length}";
                    if (username.length > Lengths.max_username_length)
                      return "too long, max length is ${Lengths.max_username_length}";
                    if (!KlangRegex.username.hasMatch(username))
                      return "not cool, can only contain letters (A-Z), dash, and underscore";
                  }
                  return null;
                },
              ),
              // uid (optional)
              KlangTextFormField(
                "uid (optional)",
                controller: _uidController,
                validator: (uid) {
                  if (uid != null || uid.length > 0) {
                    if (uid.length < Lengths.min_uid_length)
                      return "too short, min length is ${Lengths.min_uid_length}";
                    if (uid.length > Lengths.max_uid_length)
                      return "too long, max length is ${Lengths.max_uid_length}";
                    if (!KlangRegex.uid.hasMatch(uid))
                      return "not cool, can only contain letters (A-Z), dash, and underscore";
                  }
                  return null;
                },
              ),
              // password
              KlangTextFormField(
                "password",
                controller: _pswdController,
                validator: (pswd) {
                  if (pswd == null || pswd.length <= 0) {
                    return "please enter password";
                  }

                  return null;
                },
              ),
              // confirm password
              KlangTextFormField(
                "confirmPassword",
                controller: _confirmPswdController,
                validator: (pswd) {
                  if (pswd == null || pswd.length <= 0) {
                    return "please enter password";
                  }
                  return null;
                },
              ),
              KlangFormButtonPrimary(
                "create account",
                onPressed: _onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSubmit() async {
    // if any field not ok, return
    if (!_formKey.currentState.validate()) {
      return;
    }

    BlocProvider.of<TouchEnabledCubit>(context).disableTouch();

    // if create account succeeds, should reload automatically thanks to AuthCubit
    CreateAccountResult r = await FirePP.createAccount(
        email: _emailController.text,
        username: _usernameController.text,
        uid: _uidController.text,
        password: _pswdController.text);

    BlocProvider.of<TouchEnabledCubit>(context).enableTouch();

    String rm = FirePP.translateCreateAccountResult(r);
    ScaffoldMessenger.of(context).showSnackBar(
      r == CreateAccountResult.success
          ? SuccessSnackbar(rm)
          : ErrorSnackbar(rm),
    );
  }
}
