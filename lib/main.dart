import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text("klang"),
        ),
        body: _initialSetup(),
        bottomNavigationBar: BottomNavigationBar(
          items: [], // TODO: bottom nav setup
        ),
      ),
    );
  }
}

// TODO: copy stuff from ringfone that works
// - add dependencies
// - what to use, hooks, bloc, or provider?
// - determine app structure
// also, how does navigator handle lifecycle
// which one's best for app structure?
// specs:
// - everything depends on whether user signed in or not
// - how to reload active pages, but only reload background pages when shown again -> ex: if user
//   profile page in background, and user signs out, don't immediately reload page to show sign in, only reload when page shown

// structure:
// - top level: stack with loading bloc and touch enabled cubit ->
//   - loading bloc has 3 states: loading, loaded, and error. Once loaded that's it. Error shows option to try reloading
//   - touch enabled cubit can have 2 states: touch_enabled and touch_disabled. It allows other pages to block screen from touch (when signing in, etc)
// - 1st sub level: auth cubit
//   - there's a root provider that provides an auth cubit that contains auth_stream -> this is emitted to listeners
//   - auth cubit also handles all auth info - login, logout, and emits auth state: logged_in, logged_out, and logout_error, login_error
// - 2nd sub level: nav and page containers
//   - here scaffold with app bar and bottom nav is housed
//   - bottom nav has page containers
// - 3d sub level: page containers
//   - each page container has it's own navigator that houses pages
//   - everything provider in 1st level provides needs to be re-provided by page container navigator so it's children can access it

Widget _initialSetup() {
  StreamController<FirebaseApp> snapshotStream = StreamController();

  return StreamBuilder(
    stream: snapshotStream.stream,
    builder: (context, snap) {
      switch (snap.connectionState) {
        case ConnectionState.done:
          {
            if (snap.hasError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("failed to load, retry?"),
                  action: SnackBarAction(
                      label: "retry",
                      onPressed: () {
                        snapshotStream.sink
                            .addStream(Firebase.initializeApp().asStream());
                      }),
                ),
              );
              return Container();
            }
            snapshotStream.close();
            return Root();
          }
        case ConnectionState.active:
        case ConnectionState.waiting:
        default: // loading
          return Center(child: CircularProgressIndicator());
      }
    },
  );
}

/// states for auth cubit
enum AuthState { logged_in, logged_out, login_error, logout_error }
enum LoginResult {
  success,
  invalid_email,
  user_disabled,
  user_not_found,
  wrong_password,
  error,
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(AuthState initialState) : super(initialState);

  StreamController<AuthState> _streamController = StreamController();
  StreamSink<AuthState> get authStreamSink => _streamController.sink;
  Stream<AuthState> get authStream => _streamController.stream;

  Future<LoginResult> login(String email, String password) async {
    if (state == AuthState.logged_in) return LoginResult.success;
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return LoginResult.success;
    } catch (e) {
      switch ((e as FirebaseAuthException).code) {
        case "invalid-email":
          return LoginResult.invalid_email;
        case "user-disabled":
          return LoginResult.user_disabled;
        case "user-not-found":
          return LoginResult.user_not_found;
        case "wrong-password":
          return LoginResult.wrong_password;
        default: // should not happen
          throw "unknown FirebaseAuthException code -> \"${(e as FirebaseAuthException).code}\"";
          return LoginResult.error;
      }
    }
  }

  @override
  Future<void> close() {
    _streamController.close();
    return super.close();
  }
}

class Root extends StatefulWidget {
  Root({Key key}) : super(key: key);

  @override
  _RootState createState() => _RootState();
}

class _RootState extends State<Root> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [],
    );
  }
}
