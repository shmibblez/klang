import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klang/http_helper.dart';
import 'package:klang/page_router.dart';
import 'package:klang/pages/add.dart';
import 'package:klang/pages/auth_page.dart';
import 'package:klang/pages/error.dart';
import 'package:klang/pages/home.dart';
import 'package:klang/pages/klang_page.dart';
import 'package:klang/pages/log_in.dart';
import 'package:klang/pages/search.dart';
import 'package:klang/pages/user.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // static ValueKey<String> _initialSetupKey = ValueKey<String>("_InitialSetup");
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
  // final GlobalKey _blocKey = GlobalKey();
  // final GlobalKey _authKey = GlobalKey();

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
        switch (snap.connectionState) {
          case ConnectionState.done:
          case ConnectionState.active:
            {
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
            return Center(child: CircularProgressIndicator());
          default: // loading
            return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  // TODO auth cubit not working for some reason when signing in (sometimes),
  // only after signing in first and then hot reloading. Maybe auth stream getting reset or something, or not reading status properly?
  Widget _blocSetup() {
    return MultiBlocProvider(
      // key: widget._blocKey,
      providers: [
        BlocProvider(
          // key: widget._authKey,
          lazy: false,
          create: (_) => AuthCubit(null),
        ),
        BlocProvider(
          lazy: true,
          create: (_) => TouchEnabledCubit(true),
        ),
        BlocProvider(
          lazy: false,
          create: (_) => BottomNavCubit(BottomNavItem.home),
        ),
      ],
      child: Root(),
    );
  }
}

class UserState {
  UserState(this.user) {
    // uid = user?.uid;
    // loggedIn = user?.uid != null && !user.isAnonymous;
  }
  User user;
  String get uid => user?.uid;
  bool get loggedIn => user?.uid != null && !user.isAnonymous;

  @override
  operator ==(Object o) {
    return o is UserState && o.uid == this.uid && o?.loggedIn == this?.loggedIn;
  }

  @override
  int get hashCode => "$uid$loggedIn".hashCode;
}

class AuthCubit extends Cubit<UserState> {
  AuthCubit(UserState initialState) : super(initialState) {
    _resetAuth();
  }

  StreamSubscription<UserState> _streamSub;
  Stream<UserState> _stream;
  bool get loggedIn => state?.loggedIn ?? false;
  String get uid => state?.uid;

  void _resetAuth() {
    debugPrint("AuthCubit: _resetAuth()");
    _streamSub?.cancel();
    _stream = FirebaseAuth.instance
        .userChanges()
        .map<UserState>((event) => UserState(event));
    _streamSub = _stream.listen((event) {
      debugPrint("AuthCubit: new user event");
      emit(event);
    });
  }

  @override
  Future<void> close() {
    _streamSub.cancel();
    return super.close();
  }
}

// # could add message when loading
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

  static BottomNavItem _selectedItem;
  static BottomNavItem get selectedItem => _selectedItem ?? BottomNavItem.home;

  setActiveItem(BottomNavItem ni) {
    emit(ni);
    BottomNavCubit._selectedItem = ni;
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

  static String mapItemToName(BottomNavItem i) {
    switch (i) {
      case BottomNavItem.home:
        return "home";
      case BottomNavItem.search:
        return "search";
      case BottomNavItem.add:
        return "add";
      // case BottomNavItem.shuffle:
      //   return "shuffle";
      case BottomNavItem.user:
        return "user";
    }
    throw "unknown BottomNavItem received: $i";
  }

  static BottomNavItem mapNameToItem(String name) {
    switch (name.toLowerCase()) {
      case "home":
        return BottomNavItem.home;
      case "search":
        return BottomNavItem.search;
      case "add":
        return BottomNavItem.add;
      // case "shuffle":
      //   return BottomNavItem.shuffle;
      case "user":
        return BottomNavItem.user;
    }
    throw "unknown BottomNavItem name: \"$name\"";
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
  _RootState createState() {
    debugPrint("Root: createState()");
    return _RootState();
  }
}

class _RootState extends State<Root> {
  @override
  void reassemble() {
    debugPrint("_RootState reassemble()");
    BlocProvider.of<AuthCubit>(context)._resetAuth();
    super.reassemble();
  }

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<AuthCubit>(context)._resetAuth();
    return Stack(
      alignment: Alignment.center,
      children: [
        WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: MaterialApp.router(
            routerDelegate: PageRouterDelegate(),
            routeInformationParser: PageRouteInformationParser(),
            title: 'Flutter Demo',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
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

class KlangMainPage extends StatefulWidget implements KlangPage {
  // KlangMainPage({GlobalKey<_KlangMainPageState> key})
  //     : super(key: key ?? GlobalKey<_KlangMainPageState>());

  @override
  State<StatefulWidget> createState() {
    return _KlangMainPageState();
  }

  @override
  PageRoutePath get route {
    return PageRoutePath.main(
      BottomNavCubit.mapItemToName(BottomNavCubit.selectedItem),
    );
  }
}

class _KlangMainPageState extends State<KlangMainPage>
    with AutomaticKeepAliveClientMixin {
  int _selectedPageIndx = 0;
  PageController _pageController;
  StreamSubscription<BottomNavItem> _bottomNavListener;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedPageIndx);
    final BottomNavCubit bottomNavCubit = BlocProvider.of<BottomNavCubit>(
      context,
      listen: false,
    );
    _bottomNavListener = bottomNavCubit.stream.listen(
      (event) {
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
      key: widget.key,
      appBar: AppBar(
        title: Text("klang"),
        actions: [
          // if in test mode, show button that when pressed, creates sounds for testing
          if (!kReleaseMode)
            IconButton(
              onPressed: () async {
                await TestFirePP.create_test_sounds();
              },
              icon: Icon(Icons.music_note_rounded),
            )
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          HomePage(),
          SearchPage(),
          AuthPage(
            child: AddPage(),
            authFallbackPage: LoginPage(showAppBar: false),
          ),
          // AddPage(),
          // ShufflePage(),
          AuthPage(
            child: UserPage(uid: null, showAppBar: false),
            authFallbackPage: LoginPage(showAppBar: false),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: Colors.grey[400],
        selectedItemColor: Colors.grey[900],
        onTap: (newPageIndx) {
          if (_selectedPageIndx == newPageIndx) return;
          (Router.of(context).routerDelegate as PageRouterDelegate)
              .addPageRoutePath(PageRoutePath.main(
                  BottomNavCubit.mapIndxToName(newPageIndx)));
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
