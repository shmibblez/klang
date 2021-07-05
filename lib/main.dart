// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:klang/http_helper.dart';
import 'package:klang/objects/klang_sound.dart';
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

  Widget _blocSetup() {
    return MultiBlocProvider(
      // key: widget._blocKey,
      providers: [
        BlocProvider(
          lazy: true,
          create: (_) => DJCubit(),
        ),
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
          create: (_) => NavCubit(BottomNavItem.home),
        ),
      ],
      child: Root(),
    );
  }
}

/// DJCubit is in charge of emitting feel-good vibes
/// DJCubit handles sound playback & emits currently playing sound id
class DJCubit extends Cubit<String> {
  DJCubit()
      : _playa = AudioPlayer(),
        super(null);

  final AudioPlayer _playa;
  String _errorMessage;
  Duration _soundDuration;

  String get errorMessage => _errorMessage;
  Duration get soundDuration => _soundDuration;

  /// sets [sound] as [activeSound] and plays it
  /// returns [sound] file duration
  Future<Duration> play(KlangSound sound) async {
    emit(sound.id);
    await _playa.stop();
    _soundDuration = Duration.zero;
    try {
      _soundDuration = await _playa.setUrl(sound.getDownloadUrl());
      _playa.play();
      return _soundDuration;
    } catch (e, st) {
      debugPrint("***DJCubit error: $e, stackTrace: $st");
      emit(null);
      _errorMessage = e.toString();
      // TODO: show error snackbar from Root widget
      return Duration.zero;
    }
  }

  Future<void> pause() async {
    if (_playa.playing) {
      _playa.pause();
    }
  }

  Future<void> restart() async {
    await _playa.seek(Duration.zero);
    _playa.play();
  }

  Future<void> resume() async {
    if (!_playa.playing) {
      await _playa.play();
    }
  }

  Stream<Duration> onProgress() {
    return _playa.positionStream;
  }
}

class UserState {
  UserState(this.user) {
    // uid = user?.uid;
    // loggedIn = user?.uid != null && !user.isAnonymous;
    if (this.loggedIn) _setupSavedItems();
  }
  User user;
  String get uid => user?.uid;
  bool get loggedIn => user?.uid != null && !user.isAnonymous;
  Map<String, Timestamp> savedSounds;
  bool get savedItemsReady => savedSounds != null;

  @override
  operator ==(Object o) {
    return o is UserState && o.uid == this.uid && o?.loggedIn == this?.loggedIn;
  }

  @override
  int get hashCode => "$uid+$loggedIn".hashCode;

  bool isSoundSaved(String id) =>
      loggedIn && (savedSounds?.containsKey(id) ?? false);

  void notifySoundSaved(String id) {
    savedSounds.putIfAbsent(
        id,
        () => Timestamp.fromMillisecondsSinceEpoch(
            DateTime.now().millisecondsSinceEpoch));
  }

  void notifySoundUnsaved(String id) {
    savedSounds.remove(id);
  }

  /// sets up user's saved items lists
  /// if fails to load keeps retrying every 7 seconds
  Future<void> _setupSavedItems() async {
    debugPrint(
        "UserState: _setupSavedItems(), savedItemsReady: $savedItemsReady");
    if (savedItemsReady) return;
    try {
      final r = await FirePP.get_saved_items_doc();
      if (r.resultMsg == GetSavedItemsResultMsg.success) {
        this.savedSounds = r.items[0];
        debugPrint("***saved sounds: $savedSounds");
      } else {
        throw r.resultMsg;
      }
    } catch (e) {
      debugPrint("***saved sounds error, e: $e");
      await Future.delayed(Duration(seconds: 7));
      await _setupSavedItems();
    }
  }
}

class AuthCubit extends Cubit<UserState> {
  AuthCubit(UserState initialState) : super(initialState) {
    _resetAuth();
  }

  StreamSubscription<UserState> _streamSub;
  Stream<UserState> _stream;
  bool get loggedIn => state?.loggedIn ?? false;
  String get uid => state?.uid;
  Set<String> _soundsPendingSaveState = Set();

  void _resetAuth() {
    _streamSub?.cancel();
    _stream = FirebaseAuth.instance
        .userChanges()
        .map<UserState>((event) => UserState(event));
    _streamSub = _stream.listen((event) {
      debugPrint("AuthCubit: new user event");
      emit(event);
    });
  }

  void setSoundPendingSaveState(String id) {
    _soundsPendingSaveState.add(id);
  }

  void setSoundNotPendingSaveState(String id) {
    _soundsPendingSaveState.remove(id);
  }

  bool isSoundPendingSaveState(String id) {
    return _soundsPendingSaveState.contains(id);
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

class NavCubit extends Cubit<BottomNavItem> {
  NavCubit(BottomNavItem initialState) : super(initialState);

  static BottomNavItem _selectedItem;
  static BottomNavItem get selectedItem => _selectedItem ?? BottomNavItem.home;

  static void pushPath(BuildContext context, PageRoutePath path) {
    (Router.of(context).routerDelegate as PageRouterDelegate)
        .addPageRoutePath(path);
  }

  setActiveItem(BottomNavItem ni) {
    emit(ni);
    NavCubit._selectedItem = ni;
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
    return _RootState();
  }
}

class _RootState extends State<Root> {
  @override
  void reassemble() {
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
              primaryColor: Colors.green,
              primarySwatch: Colors.orange,
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
      NavCubit.mapItemToName(NavCubit.selectedItem),
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
    final NavCubit bottomNavCubit = BlocProvider.of<NavCubit>(
      context,
      listen: false,
    );
    _selectedPageIndx = bottomNavCubit.activeItemIndx();
    _pageController = PageController(initialPage: _selectedPageIndx);
    _bottomNavListener = bottomNavCubit.stream.listen(
      (event) {
        setState(() {
          _selectedPageIndx = bottomNavCubit.activeItemIndx();
          _pageController.jumpToPage(_selectedPageIndx);
        });
      },
    );
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
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          HomePage(),
          SearchPage(),
          AuthPage(
            child: AddPage(),
            authFallbackPage: LoginPage(),
          ),
          // AddPage(),
          // ShufflePage(),
          AuthPage(
            child: UserPage(uid: null),
            authFallbackPage: LoginPage(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: Colors.grey[400],
        selectedItemColor: Colors.grey[900],
        onTap: (newPageIndx) {
          if (_selectedPageIndx == newPageIndx) return;
          NavCubit.pushPath(
            context,
            PageRoutePath.main(NavCubit.mapIndxToName(newPageIndx)),
          );
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
