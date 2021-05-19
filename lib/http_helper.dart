import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum LoginResult {
  success,
  invalid_email,
  wrong_password,
  user_disabled,
  user_not_found,
}
enum CreateAccountResult {
  success,
  invalid_email,
  invalid_username,
  invalid_id,
  error,
}

/// combo between Firebase and HTTP
class FirePP {
  /// returns [LoginResult] if something went wrong
  static Future<LoginResult> login(
      {@required String email, @required String password}) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      switch ((e as FirebaseAuthException).code) {
        case "invalid-email":
          return LoginResult.invalid_email;
        case "user-disabled":
          return LoginResult.user_disabled;
        case "user-not-found":
          return LoginResult.user_not_found;
        case "wrong_password":
          return LoginResult.wrong_password;
        default:
          throw "unknown FirebaseAuthException error code: \"${(e as FirebaseAuthException).code}\"";
      }
    }
    return LoginResult.success;
  }

  ///
  static Future<CreateAccountResult> signup({
    @required String email,
    @required String username,
    @required String id,
    @required String password,
    @required String confirmPassword,
  }) async {
    // TODO: call function to create account, setup error codes, and that's it
    // might need to add firebase functions to pubspec first
    return CreateAccountResult.success;
  }
}
