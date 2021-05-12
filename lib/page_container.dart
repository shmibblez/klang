// since all page containers will need same routes, only need 1
// only exception is settings page container, that one will have special paths
import 'package:flutter/material.dart';
import 'package:klang/pages/add.dart';
import 'package:klang/pages/home.dart';
import 'package:klang/pages/search.dart';
import 'package:klang/pages/unknown.dart';
import 'package:klang/pages/user.dart';

// determines page to show as first page
enum DefaultPage { home, search, add, user /*shuffle*/ }
// content type
enum ContentType { user, sound }

class PageRouteInformationParser extends RouteInformationParser<PageRoutePath> {
  @override
  Future<PageRoutePath> parseRouteInformation(
      RouteInformation routeInformation) {
    // TODO: implement parseRouteInformation
    throw UnimplementedError();
  }

  @override
  RouteInformation restoreRouteInformation(PageRoutePath path) {
    // TODO: implement restoreRouteInformation
    return super.restoreRouteInformation(path);
  }
}

class PageRouterDelegate extends RouterDelegate<PageRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<PageRoutePath> {
  PageRouterDelegate({@required this.defaultPage});

  final DefaultPage defaultPage;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      pages: [MaterialPage(child: _getInitialPage())],
      onPopPage: (route, result) {
        if (!route.didPop(result)) return false;

        // TODO:
        return true;
      },
    );
  }

  @override
  // TODO: implement navigatorKey
  GlobalKey<NavigatorState> get navigatorKey => throw UnimplementedError();

  @override
  Future<void> setNewRoutePath(PageRoutePath configuration) {
    // TODO: implement setNewRoutePath
    throw UnimplementedError();
  }

  Widget _getInitialPage() {
    switch (this.defaultPage) {
      case DefaultPage.home:
        return HomePage();
      case DefaultPage.search:
        return SearchPage();
      case DefaultPage.add:
        return AddPage();
      // case DefaultPage.shuffle:
      //   return ShufflePage();
      case DefaultPage.user:
        return UserPage();
      default:
        return UnknownPage();
    }
  }
}

class PageRoutePath {
  // slash separated url elements
  List<String> elements;

  PageRoutePath.home() : elements = ["home"];

  PageRoutePath.search(ContentType ct, String searchStr)
      : elements = ["search", _contentTypeToStr(ct), searchStr];

  PageRoutePath.add() : elements = ["add"];

  PageRoutePath.shuffle(ContentType ct)
      : elements = ["shuffle", _contentTypeToStr(ct)];

  PageRoutePath.user(String uid) : elements = ["user", "uid"];

  static String _contentTypeToStr(ContentType ct) {
    switch (ct) {
      case ContentType.user:
        return "user";
      case ContentType.sound:
        return "sound";
      default:
        return "this should not happen";
    }
  }
}
