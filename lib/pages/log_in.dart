import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klang/constants/regex.dart';
import 'package:klang/http_helper.dart';
import 'package:klang/main.dart';
import 'package:klang/page_router.dart';
import 'package:klang/pages/klang_page.dart';
import 'package:klang/presets.dart';

class LoginPage extends StatefulWidget implements KlangPage {
  LoginPage({this.showAppBar = true});
  final showAppBar;
  @override
  State<StatefulWidget> createState() {
    return _LoginPageState();
  }

  @override
  PageRoutePath get route => PageRoutePath.login();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pswdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: Text("log in")) : null,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // email
              KlangTextFormField(
                "email",
                controller: _emailController,
                validator: (email) {
                  if (email.length <= 0) {
                    return "please enter email";
                  }
                  if (!KlangRegex.email.hasMatch(email)) {
                    return "invalid email, need to check for typos";
                  }
                  return null;
                },
              ),
              // password
              KlangTextFormField(
                "password",
                controller: _pswdController,
                validator: (pswd) {
                  if (pswd.length <= 0) {
                    return "please enter password";
                  }
                  return null;
                },
              ),
              KlangFormButtonPrimary(
                "log in",
                onPressed: _onSubmit,
              ),
              KlangFormButtonSecondary(
                "create account",
                onPressed: () {
                  (Router.of(context).routerDelegate as PageRouterDelegate)
                      .addPageRoutePath(PageRoutePath.createAccount());
                },
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

    // if login succeeds, should reload automatically thanks to AuthCubit
    LoginResult r = await FirePP.login(
        email: _emailController.text, password: _pswdController.text);

    BlocProvider.of<TouchEnabledCubit>(context).enableTouch();

    String rm = FirePP.translateLoginResult(r);
    ScaffoldMessenger.of(context).showSnackBar(
      r == LoginResult.success ? SuccessSnackbar(rm) : ErrorSnackbar(rm),
    );
  }
}
