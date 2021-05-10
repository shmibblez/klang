import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klang/page_container.dart';
import 'package:klang/pages/error.dart';

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
      home: _InitialSetup(),
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

class _InitialSetup extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _InitialSetupState();
  }
}

class _InitialSetupState extends State<_InitialSetup> {
  StreamController<FirebaseApp> snapshotStream = StreamController();

  @override
  void initState() {
    super.initState();
    snapshotStream.sink.addStream(Firebase.initializeApp().asStream());
  }

  @override
  void dispose() {
    super.dispose();
    snapshotStream.close();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: snapshotStream.stream,
      builder: (context, snap) {
        debugPrint("data: ${snap.data}");
        switch (snap.connectionState) {
          case ConnectionState.done:
          case ConnectionState.active:
            {
              debugPrint("done");
              if (snap.hasError) {
                return ErrorPage(
                  onHandleError: () {
                    // retry
                    snapshotStream.sink.addStream(
                      Firebase.initializeApp().asStream(),
                    );
                  },
                );
              }
              snapshotStream.close();
              return _blocSetup();
            }
            return Center(child: CircularProgressIndicator());
          case ConnectionState.waiting:
            debugPrint("waiting");
            return Center(child: CircularProgressIndicator());
          default: // loading
            return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _blocSetup() {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          lazy: false,
          create: (_) =>
              AuthCubit(null, FirebaseAuth.instance.authStateChanges()),
        ),
        BlocProvider(
          lazy: true,
          create: (_) => TouchEnabledCubit(false),
        )
      ],
      child: Root(),
    );
  }
}

enum LoginResult {
  success,
  invalid_email,
  user_disabled,
  user_not_found,
  wrong_password,
  error,
}

class UserState {
  UserState(this.user) {
    // uid = user?.uid;
    // loggedIn = user?.uid != null && !user.isAnonymous;
  }
  User user;
  String get uid => user?.uid;
  bool get loggedIn => user?.uid != null && !user.isAnonymous;
}

class AuthCubit extends Cubit<UserState> {
  AuthCubit(UserState initialState, Stream<User> userStream)
      : super(initialState) {
    _streamController.sink
        .addStream(userStream.map((event) => UserState(event)));
  }

  StreamController<UserState> _streamController = StreamController();
  StreamSink<UserState> get authStreamSink => _streamController.sink;
  Stream<UserState> get authStream => _streamController.stream;

  Future<LoginResult> login(String email, String password) async {
    if (state.uid != null) return LoginResult.success;
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

class TouchEnabledCubit extends Cubit<bool> {
  TouchEnabledCubit(bool touchEnabled) : super(touchEnabled);

  enableTouch() {
    emit(true);
  }

  disableTouch() {
    emit(false);
  }
}

// root provides auth and also sets up botton nav and container pages
class Root extends StatefulWidget {
  Root({Key key}) : super(key: key);

  @override
  _RootState createState() => _RootState();
}

class _RootState extends State<Root> {
  int _selectedPageIndx = 0;
  PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedPageIndx);
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("klang"),
      ),
      body: Stack(
        children: [
          // page container container
          PageView(
            controller: _pageController,
            physics: NeverScrollableScrollPhysics(),
            children: [
              PageContainer(defaultPage: DefaultPage.home),
              PageContainer(defaultPage: DefaultPage.search),
              PageContainer(defaultPage: DefaultPage.add),
              // PageContainer(defaultPage: DefaultPage.shuffle),
              PageContainer(defaultPage: DefaultPage.profile),
            ],
          ),
          // used for enabling/disabling touch
          BlocBuilder<TouchEnabledCubit, bool>(
            builder: (_, touchEnabled) {
              return IgnorePointer(child: Container());
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: Colors.grey[400],
        selectedItemColor: Colors.grey[900],
        onTap: (newPageIndx) => {
          if (newPageIndx != _selectedPageIndx)
            {
              setState(() {
                _selectedPageIndx = newPageIndx;
                _pageController.jumpToPage(_selectedPageIndx);
              })
            }
        },
        currentIndex: _selectedPageIndx,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "search",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: "add",
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.shuffle),
          //   label: "shuffle",
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_box_rounded),
            label: "account",
          ),
        ], // TODO: bottom nav setup
      ),
    );

    //  Stack(
    //   // TODO: here will go root scaffold & page containers, and TouchEnabled bloc to enable/disable touch events
    //   //.
    //   // FIXME: test before adding more stuff below
    //   children: [],
    // );
  }
}
