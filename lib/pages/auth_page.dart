import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klang/main.dart';
import 'package:klang/page_router.dart';
import 'package:klang/pages/klang_page.dart';

/// [value] stores whether listening or not
class _AuthPageDelegate extends ValueNotifier<bool> {
  _AuthPageDelegate({bool isListening}) : super(isListening);

  bool get isListening => value;

  void startListening() {
    value = true;
  }

  void stopListening() {
    value = false;
  }
}

/// auth page listens to auth state and shows page based on that
/// starts listening to auth changes
/// shows [child] when user signs in
/// shows [authFallbackPage] when user signs out
/// allows setting whether to listen to auth changes or not, based on whether is active
/// after being paused, when listening is resumed last value is retrieved and update
class AuthPage extends StatefulWidget implements KlangPage {
  AuthPage({this.child, this.authFallbackPage});

  final KlangPage child;
  final KlangPage authFallbackPage;
  final _AuthPageDelegate authDelegate = _AuthPageDelegate(isListening: true);

  @override
  State<StatefulWidget> createState() {
    return _AuthPageState();
  }

  void resumeListening() {
    authDelegate.startListening();
  }

  void stopListening() {
    authDelegate.stopListening();
  }

  @override
  PageRoutePath get route => child.route;
}

class _AuthPageState extends State<AuthPage> {
  AuthCubit _authCubit;
  StreamSubscription<UserState> _streamSubscription;
  void Function() _authPageDelegateListener;
  bool _loggedIn;

  @override
  void initState() {
    super.initState();
    _authCubit = BlocProvider.of<AuthCubit>(context);
    _streamSubscription = _authCubit.stream.listen((event) {});
    // if stop listening, pause stream listener,
    // if start listening, update based on last value and resume listening
    _authPageDelegateListener = () async {
      if (widget.authDelegate.isListening) {
        _streamSubscription.resume();
        _loggedIn = (await _authCubit.stream.last)?.loggedIn ?? false;
        setState(() {/*after update _signedIn*/});
      } else {
        _streamSubscription.pause();
      }
    };
    widget.authDelegate.addListener(_authPageDelegateListener);
    _loggedIn = _authCubit.state?.loggedIn ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return _loggedIn ? widget.child : widget.authFallbackPage;
  }

  @override
  void dispose() {
    super.dispose();
    widget.authDelegate.removeListener(_authPageDelegateListener);
  }
}
