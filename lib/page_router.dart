// since all page containers will need same routes, only need 1
// only exception is settings page container, that one will have special paths

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class PageRouteInformationParser extends RouteInformationParser<PageRoutePath> {
  @override
  Future<PageRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    final paths = Uri.parse(routeInformation.location).pathSegments;

    // debugPrint(
    //     "PageRouteInformationParser.parseRouteInformation(), paths: $paths");

    if (paths.length <= 0)
      return PageRoutePath.main("home");
    else
      switch (paths[0].toLowerCase()) {
        case "home":
          return PageRoutePath.main("home");
        case "search":
          final searchStr = paths.length >= 2 ? paths[1] : null;
          if (kIsWeb && searchStr == null) return PageRoutePath.main("search");
          return PageRoutePath.search(searchStr);
        case "add":
          return PageRoutePath.main("add");
        // case "shuffle":
        //   final ct = KlangContentTypeFromStr[path.elements[1]];
        //   // default content type will be sound
        //   _pages.add(ShufflePage(contentType: ct));
        //   break;
        case "user":
          final String uid = paths.length >= 2 ? paths[1] : null;
          if (kIsWeb && (uid == null || uid.length <= 0))
            return PageRoutePath.main("user");
          return PageRoutePath.user(uid);
        case "createaccount":
          return PageRoutePath.createAccount();
        case "login":
          return PageRoutePath.login();
        default:
          return PageRoutePath.unknown();
      }
  }

  @override
  RouteInformation restoreRouteInformation(PageRoutePath path) {
    // debugPrint(
    //     "PageRouteInformationParser.restoreRouteInformation(), paths: ${path.elements}");
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

  @override
  Future<bool> popRoute() {
    // debugPrint("PageRouterDelegate.popRoute()----------------");
    return SynchronousFuture(true);
    // return super.popRoute();
  }

  Future<void> addPageRoutePath(PageRoutePath path) async {
    // since web only has 1 page, remove and then add again
    await setNewRoutePath(path);
    if (path.isMain)
      SystemNavigator.routeInformationUpdated(location: path.path);
  }

  @override
  PageRoutePath get currentConfiguration => _pages.last.route;

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      _pages.add(_mainPage);
    }
    // debugPrint("PageRouterDelegate.build(), # pages: ${_pages.length}");
    _context = context;
    return Navigator(
      // first page is always initialPage
      key: navigatorKey,
      pages: _pages.map((w) => MaterialPage(child: w)).toList(),
      onPopPage: (route, result) {
        // debugPrint("PageRouterDelegate.Navigator.onPopPage()");
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
    // debugPrint("PageRouterDelegate.setNewRoutePath(), paths: ${path.elements}");

    // if platform is web, gets called when page added or removed (going forward or backward in history)
    if (kIsWeb) {
      if (path.isMain) {
        _makeMainPageActiveWeb(NavCubit.mapNameToItem(path.elements[0]));
        return null;
      }
      if (_pages.isNotEmpty) {
        _pages.removeLast();
      }
      _pages.add(_genPageFrom(path));
      notifyListeners();
      return null;
    }

    // if next page the same as current one, return (don't add page)
    if (path.toString() == _pages.last.route.toString()) return null;
    // if platform not web, gets called only when page added
    if (path.isMain) {
      if (_pages.last is KlangMainPage) {
        _makeMainPageActiveNotWeb(
          NavCubit.mapNameToItem(path.elements[0]),
        );
      } else {
        // shouldnt happen, will end up returning UnknownPage()
      }
    }
    // if (path.isMain) {
    //   switch (path.elements[0]) {
    //     case "":
    //     case "home":
    //       _makeMainPageActiveNotWeb(BottomNavItem.home);
    //       break;
    //     case "search":
    //       final ct = path.elements.length >= 2
    //           ? KlangContentTypeFromStr[path.elements[1]]
    //           : null;
    //       final searchStr = path.elements.length >= 3 ? path.elements[2] : null;
    //       if (ct == null || searchStr == null || searchStr.length <= 0)
    //         _makeMainPageActiveNotWeb(BottomNavItem.search);
    //       break;
    //     // case "add":
    //     //   _makeMainPageActiveWith(BottomNavItem.add);
    //     //   break;
    //     // case "shuffle":
    //     //   final ct = KlangContentTypeFromStr[path.elements[1]];
    //     //   // default content type will be sound
    //     //   _pages.add(ShufflePage(contentType: ct));
    //     //   break;
    //     case "user":
    //       final String uid =
    //           path.elements.length >= 2 ? path.elements[1] : null;
    //       if (uid == null || uid.length <= 0)
    //         _makeMainPageActiveNotWeb(BottomNavItem.user);
    //       break;
    //     default:
    //   }
    // } else {
    if (_pages.last is AuthPage) {
      (_pages.last as AuthPage).stopListening();
    }
    _pages.add(_genPageFrom(path));
    notifyListeners();
    // }

    return null;
  }

  KlangPage _genPageFrom(PageRoutePath path) {
    switch (path.elements[0].toLowerCase()) {
      case "search":
        debugPrint("***path.elements: ${path.elements}");
        final searchStr = path.elements.length >= 2 ? path.elements[1] : null;
        return SearchResultsPage(
          searchStr: searchStr,
        );
      case "user":
        final String uid = path.elements.length >= 2 ? path.elements[1] : null;
        return UserPage(uid: uid);
        break;
      case "createaccount":
        return AuthPage(
          child: UserPage(uid: null),
          authFallbackPage: CreateAccountPage(),
        );

      case "login":
        return AuthPage(
          child: UserPage(uid: null),
          authFallbackPage: LoginPage(),
        );
      default:
        return UnknownPage();
    }
  }

  /// for platforms that aren't web
  void _makeMainPageActiveNotWeb(BottomNavItem i) {
    // the only way path.isMain can be true is if first page, or if popping from nav
    // if (_pages.last is KlangMainPage) {
    //   if (BottomNavCubit.selectedItem == i) return;
    //   BlocProvider.of<BottomNavCubit>(_context, listen: false).setActiveItem(i);
    //   return;
    // }
    // int indx = _pages.indexWhere((element) => element is KlangMainPage);
    // if (indx >= 0) {
    //   _pages.removeAt(indx);
    //   _pages.insert(
    //       indx,
    //       KlangMainPagePlaceholder(
    //         route: PageRoutePath.main(BottomNavCubit.mapItemToName(i)),
    //       ));
    // }
    // if (_pages.last is KlangMainPagePlaceholder) {
    //   _pages.removeLast();
    //   _pages.add(_mainPage);
    // } else {
    //   _pages.add(_mainPage);
    // }
    if (NavCubit.selectedItem == i) return;
    BlocProvider.of<NavCubit>(_context, listen: false).setActiveItem(i);
  }

  void _makeMainPageActiveWeb(BottomNavItem i) {
    if (!(_pages.last is KlangMainPage)) {
      _pages.removeLast();
      _pages.add(_mainPage);
      notifyListeners();
    }
    BlocProvider.of<NavCubit>(_context, listen: false).setActiveItem(i);
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
  PageRoutePath.main(String sub) : elements = [sub];

  PageRoutePath.home() : elements = ["home"];

  PageRoutePath.search(String searchStr)
      : elements = [
          "search",
          // if (ct != null) _contentTypeToStr(ct),
          searchStr ?? "",
        ];

  PageRoutePath.add({bool fromParseRouteInformation = false})
      : elements = ["add"];

  // PageRoutePath.shuffle(KlangContentType ct)
  //     : elements = ["shuffle", _contentTypeToStr(ct)];

  PageRoutePath.user(String uid)
      : elements = uid == null ? ["createAccount"] : ["user", "$uid"];

  PageRoutePath.unknown() : elements = ["404"];

  PageRoutePath.createAccount() : elements = ["createAccount"];

  PageRoutePath.login() : elements = ["login"];

  bool get isMain {
    return this.elements.length == 1 &&
        rootPaths.contains(this.elements[0].toLowerCase());
  }

  String get path => this.toString();

  @override
  String toString() {
    return "/" + this.elements.join("/");
  }

  @override
  operator ==(Object o) {
    return o is PageRoutePath && o.path == this.path;
  }

  @override
  int get hashCode => this.toString().hashCode;
}
