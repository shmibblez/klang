// since all page containers will need same routes, only need 1
// only exception is settings page container, that one will have special paths

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
//     debugPrint("****new route info reported");
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

    debugPrint(
      "**parsing route info, path: ${routeInformation.location}, paths: $paths",
    );

    PageRoutePath pageRoutePath;

    if (paths.length <= 0)
      pageRoutePath = PageRoutePath.main("home");
    else
      switch (paths[0]) {
        case "home":
          pageRoutePath = PageRoutePath.main("home");
          break;
        case "search":
          final ct =
              paths.length >= 2 ? KlangContentTypeFromStr[paths[1]] : null;
          final searchStr = paths.length >= 3 ? paths[2] : null;
          if (ct == null || searchStr == null || searchStr.length <= 0)
            pageRoutePath = PageRoutePath.main("search");
          else
            pageRoutePath = PageRoutePath.search(ct, searchStr);
          break;
        case "add":
          pageRoutePath = PageRoutePath.main("add");
          break;
        // case "shuffle":
        //   final ct = KlangContentTypeFromStr[path.elements[1]];
        //   // default content type will be sound
        //   _pages.add(ShufflePage(contentType: ct));
        //   break;
        case "user":
          final String uid = paths.length >= 2 ? paths[1] : null;
          if (uid == null || uid.length <= 0)
            pageRoutePath = PageRoutePath.main("user");
          else
            pageRoutePath = PageRoutePath.user(uid);
          break;
        case "createAccount":
          pageRoutePath = PageRoutePath.createAccount();
          break;
        default:
          pageRoutePath = PageRoutePath.unknown();
          break;
      }

    return pageRoutePath;
  }

  @override
  RouteInformation restoreRouteInformation(PageRoutePath path) {
    debugPrint("restoring route info");
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
  // final List<PageRoutePath> _mainPageRoutes = [];

  @override
  PageRoutePath get currentConfiguration => _pages.last.route;

  @override
  Widget build(BuildContext context) {
    if (_pages.length <= 0) {
      _pages.add(_mainPage);
    }
    debugPrint("**PageRouterDelegate rebuilt");
    _context = context;
    return Navigator(
      // first page is always initialPage
      key: navigatorKey,
      pages: _pages.map((w) => MaterialPage(child: w as Widget)).toList(),
      onPopPage: (route, result) {
        debugPrint("&&popped page");
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
    debugPrint("**setting new route path, elements: ${path.elements}");
    if (path.elements.length <= 0) {
      _makeMainPageActiveWith(BottomNavItem.home);
    } else if (_pages.last is AuthPage) {
      (_pages.last as AuthPage).stopListening();
    }
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
    debugPrint("****just added page, _pages.length: ${_pages.length}");
    return null;
  }

  // TODO: navigation doesn't pop when on MainPage, and adds pages when on other pages like SearchResultsPage
  // might be because when pop/press back button, the following happens
  // route Info Parsed -> route Path Set
  // since when route path set I add pages, need to figure out way to know if "route Path Set" was added normally or set through pop so don't add it again if popped
  //
  // if don't add page in SetNewRoutePath, then also don't notify SystemNavigator
  //
  // NOTE: this can all be done later, as long as it works for now should be ok

  void _makeMainPageActiveWith(BottomNavItem i) {
    if (_pages.last is KlangMainPage) {
      BlocProvider.of<BottomNavCubit>(_context, listen: false).setActiveItem(i);
      SystemNavigator.routeInformationUpdated(
        location: BottomNavCubit.mapItemToName(i), //routeInformation.location,
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
      location: BottomNavCubit.mapItemToName(i), //routeInformation.location,
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
  bool popped = false;
  static final List<String> rootPaths = [
    "", // main page
    "home",
    "search",
    "add",
    "shuffle",
    "user",
  ];
  // slash separated url elements
  List<String> elements;

  /// [sub] should be a root path other than ""
  PageRoutePath.main(String sub, {bool popped})
      : elements = [sub],
        popped = popped;

  PageRoutePath.home() : elements = ["home"];

  PageRoutePath.search(KlangContentType ct, String searchStr)
      : elements = [
          "search",
          if (ct != null) _contentTypeToStr(ct),
          if (ct != null && searchStr != null) searchStr,
        ];

  PageRoutePath.add() : elements = ["add"];

  PageRoutePath.shuffle(KlangContentType ct)
      : elements = ["shuffle", _contentTypeToStr(ct)];

  PageRoutePath.user(String uid) : elements = ["user", "$uid"];

  PageRoutePath.unknown() : elements = ["404"];

  PageRoutePath.createAccount() : elements = ["createAccount"];

  PageRoutePath.login() : elements = ["login"];

  PageRoutePath.error() : elements = ["error"];

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
}

/**
 * 
 * 
 * 
 * OLD CODE, for each bottom nav main page has it's own navigator and stack
 * 
 * 
 * 
 */

// // since all page containers will need same routes, only need 1
// // only exception is settings page container, that one will have special paths
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:klang/constants.dart';
// import 'package:klang/pages/add.dart';
// import 'package:klang/pages/home.dart';
// import 'package:klang/pages/search.dart';
// import 'package:klang/pages/search_results.dart';
// import 'package:klang/pages/unknown.dart';
// import 'package:klang/pages/user.dart';

// // determines page to show as first page
// enum InitialPage { home, search, add, user /*shuffle*/ }

// class PageRouteInformationProvider extends RouteInformationProvider {
//   PageRouteInformationProvider({@required this.routeInformation});

//   RouteInformation routeInformation;

//   @override
//   void addListener(VoidCallback listener) {
//     // TODO: implement addListener
//   }

//   @override
//   void removeListener(VoidCallback listener) {
//     // TODO: implement removeListener
//   }

//   @override
//   RouteInformation get value => routeInformation;

//   set value(RouteInformation ri) {
//     this.routeInformation = ri;
//   }
// }

// // TODO: how to push to right navigator? Need to make right bottom nav active and then push route
// class PageRouteInformationParser extends RouteInformationParser<PageRoutePath> {
//   @override
//   Future<PageRoutePath> parseRouteInformation(
//       RouteInformation routeInformation) {
//     final paths = Uri.parse(routeInformation.location).pathSegments;

//     PageRoutePath pageRoutePath;

//     if (paths.length <= 0)
//       pageRoutePath = PageRoutePath.unknown();
//     else
//       switch (paths[0]) {
//         case "home":
//           pageRoutePath = PageRoutePath.home();
//           break;
//         case "search":
//           pageRoutePath = PageRoutePath.search(
//             paths.length >= 2 ? KlangContentTypeFromStr[paths[1]] : null,
//             paths.length >= 3 ? paths[2] : null,
//           );
//           break;
//         case "add":
//           pageRoutePath = PageRoutePath.add();
//           break;
//         // case "shuffle":
//         //   final ct = KlangContentTypeFromStr[path.elements[1]];
//         //   // default content type will be sound
//         //   _pages.add(ShufflePage(contentType: ct));
//         //   break;
//         case "user":
//           pageRoutePath =
//               PageRoutePath.user(paths.length >= 2 ? paths[1] : null);
//           break;
//         default:
//           pageRoutePath = PageRoutePath.unknown();
//           break;
//       }

//     return Future<PageRoutePath>.value(pageRoutePath);
//   }

//   @override
//   RouteInformation restoreRouteInformation(PageRoutePath path) {
//     return RouteInformation(location: "/" + path.elements.join("/"));
//     // return super.restoreRouteInformation(path);
//   }
// }

// class PageRouterDelegate extends RouterDelegate<PageRoutePath>
//     with ChangeNotifier, PopNavigatorRouterDelegateMixin<PageRoutePath> {
//   PageRouterDelegate({@required this.initialPage});

//   final InitialPage initialPage;
//   final List<Widget> _pages = [];

//   @override
//   Widget build(BuildContext context) {
//     return Navigator(
//       // first page is always initialPage
//       key: navigatorKey,
//       pages: [
//         MaterialPage(child: _getInitialPage()),
//         ..._pages.map((w) => MaterialPage(child: w)),
//       ],
//       onPopPage: (route, result) {
//         if (!route.didPop(result)) return false;

//         return true;
//       },
//     );
//   }

//   @override
//   GlobalKey<NavigatorState> get navigatorKey => GlobalKey<NavigatorState>();

//   @override
//   Future<void> setNewRoutePath(PageRoutePath path) {
//     if (path.elements.length <= 0)
//       _pages.add(UnknownPage());
//     else
//       switch (path.elements[0]) {
//         case "home":
//           _pages.add(HomePage());
//           notifyListeners();
//           break;
//         case "search":
//           final ct = path.elements.length >= 2
//               ? KlangContentTypeFromStr[path.elements[1]]
//               : null;
//           if (ct == null)
//             _pages.add(SearchPage());
//           else
//             _pages.add(
//               SearchResultsPage(
//                 contentType: ct,
//                 searchStr: path.elements.length >= 3 ? path.elements[2] : null,
//               ),
//             );
//           break;
//         case "add":
//           _pages.add(AddPage());
//           break;
//         // case "shuffle":
//         //   final ct = KlangContentTypeFromStr[path.elements[1]];
//         //   // default content type will be sound
//         //   _pages.add(ShufflePage(contentType: ct));
//         //   break;
//         case "user":
//           _pages.add(UserPage(
//               uid: path.elements.length >= 2 ? path.elements[1] : null));
//           break;
//         default:
//           _pages.add(UnknownPage());
//           break;
//       }

//     SystemNavigator.routeInformationUpdated(location: "location");
//     SystemNavigator.routeUpdated(routeName: "", previousRouteName: "");

//     debugPrint("--just added page, _pages.length: ${_pages.length}");
//     notifyListeners();
//     return null;
//   }

//   Widget _getInitialPage() {
//     switch (this.initialPage) {
//       case InitialPage.home:
//         return HomePage();
//       case InitialPage.search:
//         return SearchPage();
//       case InitialPage.add:
//         return AddPage();
//       // case DefaultPage.shuffle:
//       //   return ShufflePage();
//       case InitialPage.user:
//         return UserPage(uid: null);
//       default:
//         return UnknownPage();
//     }
//   }

//   String _initialPageName() {
//     switch (this.initialPage) {
//       case InitialPage.home:
//         return "home";
//       case InitialPage.search:
//         return "search";
//       case InitialPage.add:
//         return "add";
//       // case InitialPage.shuffle:
//       //   return "home";
//       case InitialPage.user:
//         return "user";
//         break;
//       default:
//         return "this should not happen";
//     }
//   }
// }

// class PageRoutePath {
//   static final List<String> rootPaths = [
//     "home",
//     "search",
//     "add",
//     "shuffle",
//     "user",
//   ];
//   // slash separated url elements
//   List<String> elements;

//   PageRoutePath.home() : elements = ["home"];

//   PageRoutePath.search(KlangContentType ct, String searchStr)
//       : elements = ["search", _contentTypeToStr(ct), searchStr];

//   PageRoutePath.add() : elements = ["add"];

//   PageRoutePath.shuffle(KlangContentType ct)
//       : elements = ["shuffle", _contentTypeToStr(ct)];

//   PageRoutePath.user(String uid) : elements = ["user", "uid"];

//   PageRoutePath.unknown() : elements = ["404"];

//   static String _contentTypeToStr(KlangContentType ct) {
//     switch (ct) {
//       case KlangContentType.user:
//         return "user";
//       case KlangContentType.sound:
//         return "sound";
//       default:
//         return "this should not happen";
//     }
//   }
// }
