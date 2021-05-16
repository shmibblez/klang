import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klang/page_container.dart';
import 'package:klang/pages/add.dart';
import 'package:klang/pages/auth_page.dart';
import 'package:klang/pages/error.dart';
import 'package:klang/pages/home.dart';
import 'package:klang/pages/log_in.dart';
import 'package:klang/pages/search.dart';
import 'package:klang/pages/user.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return _InitialSetup();
  }
}

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
          create: (_) => TouchEnabledCubit(true),
        ),
        BlocProvider(
          lazy: false,
          create: (_) => BottomNavCubit(BottomNavItem.home),
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

enum BottomNavItem { home, search, add, /*shuffle,*/ user }

class BottomNavCubit extends Cubit<BottomNavItem> {
  BottomNavCubit(BottomNavItem initialState) : super(initialState);

  setActiveItem(BottomNavItem ni) {
    debugPrint("--setting bottom nav cubit active item, item: $ni");
    // if (ni != state)
    emit(ni);
  }

  static String mapIndxToName(int indx) {
    switch (indx) {
      case 0:
        return "home";
      case 1:
        return "search";
      case 2:
        return "add";
      // case 3:
      //   return "shuffle";
      case 3:
        return "user";
    }
    throw "bottom nav indx out of range, max is 3, received \"$indx\"";
  }

  int activeItemIndx() {
    switch (state) {
      case BottomNavItem.home:
        return 0;
      case BottomNavItem.search:
        return 1;
      case BottomNavItem.add:
        return 2;
      // case BottomNavItem.shuffle:
      //   return 3;
      case BottomNavItem.user:
        return 3;
    }
    throw "unknown active item \"$state\"";
  }
}

// root provides auth and also sets up botton nav and container pages
class Root extends StatefulWidget {
  Root({Key key}) : super(key: key);

  @override
  _RootState createState() => _RootState();
}

class _RootState extends State<Root> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        MaterialApp.router(
          routeInformationProvider: PageRouteInformationProvider(
            routeInformation: RouteInformation(location: "/home"),
          ),
          routerDelegate: PageRouterDelegate(),
          routeInformationParser: PageRouteInformationParser(),
          // routeInformationProvider: PageRouteInformationProvider(
          //   routeInformation: RouteInformation(location: "/home"),
          // ),
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
        ), // used for enabling/disabling touch
        BlocBuilder<TouchEnabledCubit, bool>(
          builder: (_, touchEnabled) {
            return Offstage(
              offstage: touchEnabled,
              child: AbsorbPointer(
                child: Container(
                  color: Color(0x55555555),
                  child: Center(child: CircularProgressIndicator()),
                ),
                absorbing: !touchEnabled,
              ),
            );
          },
        ),
      ],
    );
  }
}

class KlangMainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _KlangMainPageState();
  }
}

class _KlangMainPageState extends State<KlangMainPage>
    with AutomaticKeepAliveClientMixin {
  int _selectedPageIndx = 0;
  PageController _pageController;
  StreamSubscription<BottomNavItem> _bottomNavListener;

  @override
  void initState() {
    debugPrint("-KlangMainPageState initState called");
    super.initState();
    _pageController = PageController(initialPage: _selectedPageIndx);
    final BottomNavCubit bottomNavCubit = BlocProvider.of<BottomNavCubit>(
      context,
      listen: false,
    );
    _bottomNavListener = bottomNavCubit.stream.listen(
      (event) {
        debugPrint(
            "--bottom nav selected index changed, old index: $_selectedPageIndx");
        setState(() {
          _selectedPageIndx = bottomNavCubit.activeItemIndx();
          _pageController.jumpToPage(_selectedPageIndx);
        });
      },
    );
    _selectedPageIndx = bottomNavCubit.activeItemIndx();
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
    _bottomNavListener.cancel();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("klang"),
      ),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          // Router(
          //   // backButtonDispatcher: , TODO: setup root back button dispatcher, could setup list that keeps main bottom nav order, and if no page to pop for current nav container, set previous item in bottom nav order list as active screen. If bottom nav order list empty and back requested exit app
          //.
          //   routerDelegate:
          //       PageRouterDelegate(initialPage: InitialPage.home),
          //   routeInformationParser: PageRouteInformationParser(),
          //   routeInformationProvider: PageRouteInformationProvider(
          //     routeInformation: RouteInformation(location: "/home"),
          //   ),
          // ),
          HomePage(),
          SearchPage(),
          AddPage(),
          // ShufflePage(),
          AuthPage(
            child: UserPage(uid: null),
            authFallbackPage: LoginPage(showAppBar: false),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: Colors.grey[400],
        selectedItemColor: Colors.grey[900],
        onTap: (newPageIndx) {
          (Router.of(context).routerDelegate as PageRouterDelegate)
              .setNewRoutePath(PageRoutePath.main(
            BottomNavCubit.mapIndxToName(newPageIndx),
          ));
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
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
