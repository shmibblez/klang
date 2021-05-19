import 'package:flutter/material.dart';
import 'package:klang/page_router.dart';
import 'package:klang/pages/klang_page.dart';

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // email
              TextFormField(
                controller: _emailController,
                validator: (email) {
                  if (email == null || email.length <= 0) {
                    return "please enter email";
                  }
                  return null;
                },
              ),
              // password
              TextFormField(
                controller: _pswdController,
                validator: (pswd) {
                  if (pswd == null || pswd.length <= 0) {
                    return "please enter password";
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () {},
                child: Text("log in"),
              ),
              OutlinedButton(
                onPressed: () {
                  (Router.of(context).routerDelegate as PageRouterDelegate)
                      .addPageRoutePath(PageRoutePath.createAccount());
                },
                child: Text("create account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
