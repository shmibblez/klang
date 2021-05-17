import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klang/main.dart';
import 'package:klang/page_container.dart';
import 'package:klang/pages/klang_page.dart';

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
              // confirm password
              TextFormField(
                controller: _confirmPswdController,
                validator: (pswd) {
                  if (pswd == null || pswd.length <= 0) {
                    return "please enter password";
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: check fields and make sure güd,
                  _formKey.currentState.validate();

                  // before calling http function to create account
                  BlocProvider.of<TouchEnabledCubit>(context, listen: false)
                      .disableTouch();

                  // TODO: call http function to create account here
                  // notify fail with snackbar with red background and white text (make custom error snackbar widget)

                  // after calling http function to create account
                  BlocProvider.of<TouchEnabledCubit>(context, listen: false)
                      .enableTouch();
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
