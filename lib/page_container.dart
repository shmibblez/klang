// since all page containers will need same routes, only need 1
// only exception is settings page container, that one will have special paths
import 'package:flutter/material.dart';
import 'package:klang/constants.dart';
import 'package:klang/pages/add.dart';
import 'package:klang/pages/home.dart';
import 'package:klang/pages/search.dart';
import 'package:klang/pages/search_results.dart';
import 'package:klang/pages/unknown.dart';
import 'package:klang/pages/user.dart';

// determines page to show as first page
enum InitialPage { home, search, add, user /*shuffle*/ }

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

  set value(RouteInformation ri) {
    this.routeInformation = ri;
  }
}

// TODO: how to push to right navigator? Need to make right bottom nav active and then push route
class PageRouteInformationParser extends RouteInformationParser<PageRoutePath> {
  @override
  Future<PageRoutePath> parseRouteInformation(
      RouteInformation routeInformation) {
    final paths = Uri.parse(routeInformation.location).pathSegments;

    PageRoutePath pageRoutePath;

    if (paths.length <= 0)
      pageRoutePath = PageRoutePath.unknown();
    else
      switch (paths[0]) {
        case "home":
          pageRoutePath = PageRoutePath.home();
          break;
        case "search":
          pageRoutePath = PageRoutePath.search(
            paths.length >= 2 ? KlangContentTypeFromStr[paths[1]] : null,
            paths.length >= 3 ? paths[2] : null,
          );
          break;
        case "add":
          pageRoutePath = PageRoutePath.add();
          break;
        // case "shuffle":
        //   final ct = KlangContentTypeFromStr[path.elements[1]];
        //   // default content type will be sound
        //   _pages.add(ShufflePage(contentType: ct));
        //   break;
        case "user":
          pageRoutePath =
              PageRoutePath.user(paths.length >= 2 ? paths[1] : null);
          break;
        default:
          pageRoutePath = PageRoutePath.unknown();
          break;
      }

    return Future<PageRoutePath>.value(pageRoutePath);
  }

  @override
  RouteInformation restoreRouteInformation(PageRoutePath path) {
    return RouteInformation(location: "/" + path.elements.join("/"));
    // return super.restoreRouteInformation(path);
  }
}

class PageRouterDelegate extends RouterDelegate<PageRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<PageRoutePath> {
  PageRouterDelegate({@required this.initialPage});

  final InitialPage initialPage;
  final List<Widget> _pages = [];

  @override
  Widget build(BuildContext context) {
    return Navigator(
      // first page is always initialPage
      key: navigatorKey,
      pages: [
        MaterialPage(child: _getInitialPage()),
        ..._pages.map((w) => MaterialPage(child: w)),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) return false;

        return true;
      },
    );
  }

  @override
  GlobalKey<NavigatorState> get navigatorKey => GlobalKey<NavigatorState>();

  @override
  Future<void> setNewRoutePath(PageRoutePath path) {
    if (path.elements.length <= 0)
      _pages.add(UnknownPage());
    else
      switch (path.elements[0]) {
        case "home":
          _pages.add(HomePage());
          notifyListeners();
          break;
        case "search":
          final ct = path.elements.length >= 2
              ? KlangContentTypeFromStr[path.elements[1]]
              : null;
          if (ct == null)
            _pages.add(SearchPage());
          else
            _pages.add(
              SearchResultsPage(
                contentType: ct,
                searchStr: path.elements.length >= 3 ? path.elements[2] : null,
              ),
            );
          break;
        case "add":
          _pages.add(AddPage());
          break;
        // case "shuffle":
        //   final ct = KlangContentTypeFromStr[path.elements[1]];
        //   // default content type will be sound
        //   _pages.add(ShufflePage(contentType: ct));
        //   break;
        case "user":
          _pages.add(UserPage(
              uid: path.elements.length >= 2 ? path.elements[1] : null));
          break;
        default:
          _pages.add(UnknownPage());
          break;
      }

    debugPrint("--just added page, _pages.length: ${_pages.length}");
    notifyListeners();
    return null;
  }

  Widget _getInitialPage() {
    switch (this.initialPage) {
      case InitialPage.home:
        return HomePage();
      case InitialPage.search:
        return SearchPage();
      case InitialPage.add:
        return AddPage();
      // case DefaultPage.shuffle:
      //   return ShufflePage();
      case InitialPage.user:
        return UserPage(uid: null);
      default:
        return UnknownPage();
    }
  }

  String _initialPageName() {
    switch (this.initialPage) {
      case InitialPage.home:
        return "home";
      case InitialPage.search:
        return "search";
      case InitialPage.add:
        return "add";
      // case InitialPage.shuffle:
      //   return "home";
      case InitialPage.user:
        return "user";
        break;
      default:
        return "this should not happen";
    }
  }
}

class PageRoutePath {
  static final List<String> rootPaths = [
    "home",
    "search",
    "add",
    "shuffle",
    "user",
  ];
  // slash separated url elements
  List<String> elements;

  PageRoutePath.home() : elements = ["home"];

  PageRoutePath.search(KlangContentType ct, String searchStr)
      : elements = ["search", _contentTypeToStr(ct), searchStr];

  PageRoutePath.add() : elements = ["add"];

  PageRoutePath.shuffle(KlangContentType ct)
      : elements = ["shuffle", _contentTypeToStr(ct)];

  PageRoutePath.user(String uid) : elements = ["user", "uid"];

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
