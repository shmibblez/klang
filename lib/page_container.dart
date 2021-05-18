// since all page containers will need same routes, only need 1
// only exception is settings page container, that one will have special paths

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:history/history.dart';
import 'package:klang/constants.dart';
import 'package:klang/main.dart';
import 'package:klang/pages/auth_page.dart';
import 'package:klang/pages/create_account.dart';
import 'package:klang/pages/klang_page.dart';
import 'package:klang/pages/log_in.dart';
import 'package:klang/pages/search_results.dart';
import 'package:klang/pages/unknown.dart';
import 'package:klang/pages/user.dart';

// class PageRouteInformationProvider extends RouteInformationProvider
//     with ChangeNotifier {
//   PageRouteInformationProvider({RouteInformation initialRouteInformation})
//       : _value = initialRouteInformation;

//   RouteInformation _value;

//   @override
//   void routerReportsNewRouteInformation(RouteInformation routeInformation) {
//     super.routerReportsNewRouteInformation(routeInformation);
//     // PlatformRouteInformationProvider;
//     if (this._value == routeInformation) return;
//     SystemNavigator.routeInformationUpdated(
//       location: routeInformation.location,
//       state: routeInformation.state,
//     );
//     this._value = routeInformation;
//     notifyListeners();
//   }

//   @override
//   void addListener(VoidCallback listener) {
//     super.addListener(listener);
//   }

//   @override
//   void removeListener(VoidCallback listener) {
//     super.removeListener(listener);
//   }

//   @override
//   RouteInformation get value => _value;
// }

class PageBackButtonDispatcher extends RootBackButtonDispatcher {
  @override
  Future<bool> invokeCallback(Future<bool> defaultValue) {
    debugPrint("PageBackButtonDispatcher.invokeCallback()");
    return super.invokeCallback(defaultValue);
  }

  @override
  void addCallback(ValueGetter<Future<bool>> callback) {
    debugPrint("PageBackButtonDispatcher.addCallback()");
    super.addCallback(callback);
  }

  @override
  void removeCallback(ValueGetter<Future<bool>> callback) {
    debugPrint("PageBackButtonDispatcher.removeCallback()");
    super.removeCallback(callback);
  }

  @override
  Future<bool> didPopRoute() {
    debugPrint("PageBackButtonDispatcher.didPopRoute()");
    return super.didPopRoute();
  }
}

class PageRouteInformationParser extends RouteInformationParser<PageRoutePath> {
  @override
  Future<PageRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    final paths = Uri.parse(routeInformation.location).pathSegments;

    debugPrint(
        "PageRouteInformationParser.parseRouteInformation(), paths: $paths");

    PageRoutePath pageRoutePath;

    if (paths.length <= 0)
      pageRoutePath =
          PageRoutePath.main("home", fromParseRouteInformation: true);
    else
      switch (paths[0]) {
        case "home":
          pageRoutePath =
              PageRoutePath.main("home", fromParseRouteInformation: true);
          break;
        case "search":
          final ct =
              paths.length >= 2 ? KlangContentTypeFromStr[paths[1]] : null;
          final searchStr = paths.length >= 3 ? paths[2] : null;
          if (ct == null || searchStr == null || searchStr.length <= 0)
            pageRoutePath =
                PageRoutePath.main("search", fromParseRouteInformation: true);
          else
            pageRoutePath = PageRoutePath.search(ct, searchStr,
                fromParseRouteInformation: true);
          break;
        case "add":
          pageRoutePath =
              PageRoutePath.main("add", fromParseRouteInformation: true);
          break;
        // case "shuffle":
        //   final ct = KlangContentTypeFromStr[path.elements[1]];
        //   // default content type will be sound
        //   _pages.add(ShufflePage(contentType: ct));
        //   break;
        case "user":
          final String uid = paths.length >= 2 ? paths[1] : null;
          if (uid == null || uid.length <= 0)
            pageRoutePath =
                PageRoutePath.main("user", fromParseRouteInformation: true);
          else
            pageRoutePath =
                PageRoutePath.user(uid, fromParseRouteInformation: true);
          break;
        case "createAccount":
          pageRoutePath =
              PageRoutePath.createAccount(fromParseRouteInformation: true);
          break;
        default:
          pageRoutePath =
              PageRoutePath.unknown(fromParseRouteInformation: true);
          break;
      }

    return pageRoutePath;
  }

  @override
  RouteInformation restoreRouteInformation(PageRoutePath path) {
    debugPrint(
        "PageRouteInformationParser.restoreRouteInformation(), paths: ${path.elements}");
    return RouteInformation(location: "/" + path.elements.join("/"));
    // return super.restoreRouteInformation(path);
  }
}

class PageRouterDelegate extends RouterDelegate<PageRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<PageRoutePath> {
  final List<KlangPage> _pages = [];
  final KlangMainPage _mainPage = KlangMainPage();
  BuildContext _context;
  static final _navigatorKey = GlobalKey<NavigatorState>();
  final BrowserHistory _history = BrowserHistory();
  int _historySize = 1;

  // final List<PageRoutePath> _mainPageRoutes = [];

  @override
  Future<bool> popRoute() {
    debugPrint("PageRouterDelegate.popRoute()----------------");
    return SynchronousFuture(true);
    // return super.popRoute();
  }

  @override
  PageRoutePath get currentConfiguration => _pages.last.route;

  @override
  Widget build(BuildContext context) {
    if (_pages.length <= 0) {
      _pages.add(_mainPage);
    }
    debugPrint("PageRouterDelegate.build(), # pages: ${_pages.length}");
    _context = context;
    return Navigator(
      // first page is always initialPage
      key: navigatorKey,
      pages: _pages.map((w) => MaterialPage(child: w as Widget)).toList(),
      onPopPage: (route, result) {
        debugPrint("PageRouterDelegate.Navigator.onPopPage()");
        if (!route.didPop(result)) return false;
        if (_pages.length > 1) {
          if (_pages.length > 2 && _pages[_pages.length - 2] is AuthPage) {
            (_pages[_pages.length - 2] as AuthPage).resumeListening();
          }
          _pages.removeLast();
          notifyListeners();
          // if (_pages.last is KlangMainPagePlaceholder) {
          //   BottomNavItem i = BottomNavCubit.mapNameToItem(
          //     _pages.last.route.elements[0],
          //   );
          //   _pages.removeLast();
          //   _pages.add(_mainPage);
          //   BlocProvider.of<BottomNavCubit>(_context, listen: false)
          //       .setActiveItem(i);
          // }
          // _pagePaths.removeLast();
          if (!(_pages.last is KlangMainPage))
            navigatorKey.currentState.finalizeRoute(route);
          return true;
        }
        return true;
      },
    );
  }

  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  @override
  Future<void> setNewRoutePath(PageRoutePath path) {
    debugPrint("PageRouterDelegate.setNewRoutePath(), paths: ${path.elements}");
    // if (path.fromParseRouteInformation) {
    //   if (path.isMain) {
    //     debugPrint("-popped main path, changing selected item");
    //     _makeMainPageActiveWith(BottomNavCubit.mapNameToItem(path.elements[0]));
    //     return null;
    //   } else if (path.toString() ==
    //       _pages[_pages.length - 2].route.toString()) {

    //     _pages.removeLast();
    //     notifyListeners();
    //     return null;
    //   }
    // }
    debugPrint("action index: ${_history.action.index}");
    if (_history.length == _historySize) {
      // _history.
    }
    // if back stack popped
    // if (_history.length > 1 && _history.length == _historySize) {
    //   return null;
    // } else if (_history.length <= 0) {
    //   _makeMainPageActiveWith(BottomNavItem.home);
    // }
    // // history.length;
    // debugPrint("-browser history length: ${_history.length}");
    // debugPrint("-browser history current location: ${_history.location}");
    // if (_pages.last is AuthPage) {
    //   (_pages.last as AuthPage).stopListening();
    // }
    switch (path.elements[0]) {
      case "":
      case "home":
        _makeMainPageActiveWith(BottomNavItem.home);
        break;
      case "search":
        final ct = path.elements.length >= 2
            ? KlangContentTypeFromStr[path.elements[1]]
            : null;
        final searchStr = path.elements.length >= 3 ? path.elements[2] : null;
        if (ct == null || searchStr == null || searchStr.length <= 0)
          _makeMainPageActiveWith(BottomNavItem.search);
        else {
          _pages.add(
            SearchResultsPage(
              contentType: ct,
              searchStr: searchStr,
            ),
          );
          notifyListeners();
        }
        break;
      case "add":
        _makeMainPageActiveWith(BottomNavItem.add);
        break;
      // case "shuffle":
      //   final ct = KlangContentTypeFromStr[path.elements[1]];
      //   // default content type will be sound
      //   _pages.add(ShufflePage(contentType: ct));
      //   break;
      case "user":
        final String uid = path.elements.length >= 2 ? path.elements[1] : null;
        if (uid == null || uid.length <= 0)
          _makeMainPageActiveWith(BottomNavItem.user);
        else {
          _pages.add(UserPage(uid: uid));
          notifyListeners();
        }
        break;
      case "createAccount":
        _pages.add(
          AuthPage(
            child: UserPage(uid: null),
            authFallbackPage: CreateAccountPage(),
          ),
        );
        notifyListeners();
        break;
      case "login":
        _pages.add(
          AuthPage(
            child: UserPage(uid: null),
            authFallbackPage: LoginPage(),
          ),
        );
        notifyListeners();
        break;
      default:
        _pages.add(UnknownPage());
        notifyListeners();
        break;
    }
    return null;
  }

  // TODO: navigation doesn't pop when on MainPage, and adds pages when on other pages like SearchResultsPage
  // might be because when pop/press back button, the following happens
  // route Info Parsed -> route Path Set
  // since when route path set I add pages, need to figure out way to know if "route Path Set" was added normally or set through pop so don't add it again if popped
  //
  // if don't add page in SetNewRoutePath, then also don't notify SystemNavigator
  //
  // NOTE: this can all be done later, as long as it works for now should be ok (auth might be off, along with other things, so, who knows?s)
  //
  // also: global key duplicate error with KlangMainPage may be because it's stored in variable and in Navigator _pages widget tree
  // fix: store static final root-level mainPageKey in Root widget, and add KlangMainPage widget with key instead of storing in variable and adding that
  // - do this after successfuly setting up navigation though, shouldn't influence how it works, just causes unecessary rebuilds

  void _makeMainPageActiveWith(BottomNavItem i) {
    if (_pages.last is KlangMainPage) {
      if (BottomNavCubit.selectedItem == i) return;
      BlocProvider.of<BottomNavCubit>(_context).setActiveItem(i);
      SystemNavigator.routeInformationUpdated(
        location: _pages.last.route.toString(), //routeInformation.location,
        // state: routeInformation.state,
      );
      return;
    }
    int indx = _pages.indexWhere((element) => element is KlangMainPage);
    if (indx >= 0) {
      _pages.removeAt(indx);
      _pages.insert(
          indx,
          KlangMainPagePlaceholder(
            route: PageRoutePath.main(BottomNavCubit.mapItemToName(i)),
          ));
    }
    if (_pages.last is KlangMainPagePlaceholder) {
      _pages.removeLast();
      _pages.add(_mainPage);
    } else {
      _pages.add(_mainPage);
    }
    BlocProvider.of<BottomNavCubit>(_context, listen: false).setActiveItem(i);
    SystemNavigator.routeInformationUpdated(
      location: _pages.last.route.toString(), //routeInformation.location,
      // state: routeInformation.state,
    );
  }

  // // gets selected bottom nav item name
  // String _activeMainPageItem() {
  //   int indx = BlocProvider.of<BottomNavCubit>(_context).activeItemIndx();
  //   return BottomNavCubit.mapIndxToName(indx);
  // }
}

class KlangMainPagePlaceholder extends Container implements KlangPage {
  KlangMainPagePlaceholder({@required PageRoutePath route}) : _path = route;
  final PageRoutePath _path;
  @override
  PageRoutePath get route => _path;
}

class PageRoutePath {
  bool fromParseRouteInformation = false;
  static final List<String> rootPaths = [
    // "", // main page
    "home",
    "search",
    "add",
    "shuffle",
    "user",
  ];
  // slash separated url elements
  List<String> elements;

  /// [sub] should be a root path other than ""
  PageRoutePath.main(String sub, {bool fromParseRouteInformation = false})
      : elements = [sub],
        this.fromParseRouteInformation = fromParseRouteInformation;

  PageRoutePath.home({bool fromParseRouteInformation = false})
      : elements = ["home"],
        this.fromParseRouteInformation = fromParseRouteInformation;

  PageRoutePath.search(KlangContentType ct, String searchStr,
      {bool fromParseRouteInformation = false})
      : elements = [
          "search",
          if (ct != null) _contentTypeToStr(ct),
          if (ct != null && searchStr != null) searchStr,
        ],
        this.fromParseRouteInformation = fromParseRouteInformation;

  PageRoutePath.add({bool fromParseRouteInformation = false})
      : elements = ["add"],
        this.fromParseRouteInformation = fromParseRouteInformation;

  PageRoutePath.shuffle(KlangContentType ct,
      {bool fromParseRouteInformation = false})
      : elements = ["shuffle", _contentTypeToStr(ct)],
        this.fromParseRouteInformation = fromParseRouteInformation;

  PageRoutePath.user(String uid, {bool fromParseRouteInformation = false})
      : elements = ["user", if (uid != null) "$uid"],
        this.fromParseRouteInformation = fromParseRouteInformation;

  PageRoutePath.unknown({bool fromParseRouteInformation = false})
      : elements = ["404"],
        this.fromParseRouteInformation = fromParseRouteInformation;

  PageRoutePath.createAccount({bool fromParseRouteInformation = false})
      : elements = ["createAccount"],
        this.fromParseRouteInformation = fromParseRouteInformation;

  PageRoutePath.login({bool fromParseRouteInformation = false})
      : elements = ["login"],
        this.fromParseRouteInformation = fromParseRouteInformation;

  PageRoutePath.error({bool fromParseRouteInformation = false})
      : elements = ["error"],
        this.fromParseRouteInformation = fromParseRouteInformation;

  bool get isMain {
    if (this.elements[0] == "search" && this.elements.length >= 3) return false;
    if (this.elements[0] == "user" && this.elements.length >= 2) return false;
    return rootPaths.contains(this.elements[0]);
  }

  static String _contentTypeToStr(KlangContentType ct) {
    switch (ct) {
      case KlangContentType.user:
        return "user";
      case KlangContentType.sound:
        return "sound";
      default:
        return "this should not happen";
    }
  }

  @override
  String toString() {
    return "/" + this.elements.join("/");
  }
}
