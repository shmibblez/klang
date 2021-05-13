// since all page containers will need same routes, only need 1
// only exception is settings page container, that one will have special paths

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klang/constants.dart';
import 'package:klang/main.dart';
import 'package:klang/pages/search_results.dart';
import 'package:klang/pages/unknown.dart';
import 'package:klang/pages/user.dart';

class PageRouteInformationProvider extends RouteInformationProvider {
  PageRouteInformationProvider({@required this.routeInformation});

  RouteInformation routeInformation;

  @override
  void addListener(VoidCallback listener) {
    // TODO: implement addListener
  }

  @override
  void removeListener(VoidCallback listener) {
    // TODO: implement removeListener
  }

  @override
  RouteInformation get value => routeInformation;
}

// TODO: how to push to right navigator? Need to make right bottom nav active and then push route
class PageRouteInformationParser extends RouteInformationParser<PageRoutePath> {
  @override
  Future<PageRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    final paths = Uri.parse(routeInformation.location).pathSegments;

    debugPrint(
        "--parsing route info, path: ${routeInformation.location}, paths: $paths");

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
        default:
          pageRoutePath = PageRoutePath.unknown();
          break;
      }

    return pageRoutePath;
  }

  @override
  RouteInformation restoreRouteInformation(PageRoutePath path) {
    return RouteInformation(location: "/" + path.elements.join("/"));
    // return super.restoreRouteInformation(path);
  }
}

class PageRouterDelegate extends RouterDelegate<PageRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<PageRoutePath> {
  final List<Widget> _pages = [];
  final KlangMainPage _mainPage = KlangMainPage();
  BuildContext _context;
  static final _navigatorKey =
      GlobalKey<NavigatorState>(); // TODO: test with this, if doesn't work:
  // TODO: if above fails need to:
  // - add key to KlangMainPage
  // - add placeholder for KlangMainPage, and if either pop or add new page move _main page to where placeholder is
  // - test above, in hopes that _mainPage will never be rebuilt and there will only be 1 in widget tree so no complaints from framework

  @override
  Widget build(BuildContext context) {
    debugPrint("-PageRouterDelegate rebuilt");
    _context = context;
    return Navigator(
      // first page is always initialPage
      key: navigatorKey,
      pages: [
        MaterialPage(child: _mainPage),
        ..._pages.map((w) => MaterialPage(child: w)),
      ],
      onPopPage: (route, result) {
        debugPrint("--popped page");
        if (!route.didPop(result)) return false;
        if (_pages.length > 1) {
          _pages.removeLast();
          return true;
        }
        return false;
      },
    );
  }

  @override
  GlobalKey<NavigatorState> get navigatorKey =>
      _navigatorKey; // used to be GlobalKey<NavigatorState>(); // TODO: if test fails need to undo

  @override
  Future<void> setNewRoutePath(PageRoutePath path) {
    debugPrint("--setting new route path, elements: ${path.elements}");
    if (path.elements.length <= 0) {
      _makeMainPageActiveWith(BottomNavItem.home);
    } else
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
          final String uid =
              path.elements.length >= 2 ? path.elements[1] : null;
          if (uid == null || uid.length <= 0)
            _makeMainPageActiveWith(BottomNavItem.user);
          else {
            _pages.add(UserPage(uid: uid));
            notifyListeners();
          }
          break;
        default:
          _pages.add(UnknownPage());
          notifyListeners();
          break;
      }

    debugPrint("----just added page, _pages.length: ${_pages.length}");
    return null;
  }

  void _makeMainPageActiveWith(BottomNavItem i) {
    if (_pages.length > 0 && !(_pages.last is KlangMainPage)) {
      _pages.add(_mainPage);
      notifyListeners();
    }
    BlocProvider.of<BottomNavCubit>(_context, listen: false).setActiveItem(i);
  }
}

class PageRoutePath {
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
  PageRoutePath.main(String sub) : elements = [sub];

  PageRoutePath.home() : elements = ["home"];

  PageRoutePath.search(KlangContentType ct, String searchStr)
      : elements = ["search", _contentTypeToStr(ct), searchStr];

  PageRoutePath.add() : elements = ["add"];

  PageRoutePath.shuffle(KlangContentType ct)
      : elements = ["shuffle", _contentTypeToStr(ct)];

  PageRoutePath.user(String uid) : elements = ["user", "$uid"];

  PageRoutePath.unknown() : elements = ["404"];

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
