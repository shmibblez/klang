import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:klang/constants/transpiled_constants.dart';

enum LoginResult {
  success,
  invalid_email,
  wrong_password,
  user_disabled,
  user_not_found,
}

enum CreateAccountResult {
  success,
  invalid_username,
  invalid_email,
  invalid_uid,
  invalid_pswd,
  missionFailed,
}

/// combo between Firebase and HTTP
class FirePP {
  static final bool _testing = true;
  static final _functionsPort = "5001";

  static String translateLoginResult(LoginResult l) {
    switch (l) {
      case LoginResult.success:
        return "success";
      case LoginResult.invalid_email:
        return "invalid email";
      case LoginResult.wrong_password:
        return "wrong password";
      case LoginResult.user_disabled:
        return "user not enabled";
      case LoginResult.user_not_found:
        return "unknown email - it doesn't correspond to an existing user";
    }
    throw "unknow LoginResult: \"$l\"";
  }

  static String translateCreateAccountResult(CreateAccountResult c) {
    switch (c) {
      case CreateAccountResult.success:
        return "success";
      case CreateAccountResult.invalid_username:
        return "invalid username";
      case CreateAccountResult.invalid_email:
        return "invalid email";
      case CreateAccountResult.invalid_uid:
        return "invalid uid";
      case CreateAccountResult.invalid_pswd:
        return "invalid password";
      case CreateAccountResult.missionFailed:
        return "something went wrong, please try again later or if you can, send us an email describing what went wrong and we'll try to fix it asap";
    }
    throw "unknown CreateAccountResult: \"$c\"";
  }

  /// returns [LoginResult] to inform result
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

  /// call http create account function
  /// returns [CreateAccountResult] to inform result
  static Future<CreateAccountResult> createAccount({
    @required String email,
    @required String username,
    @required String uid,
    @required String password,
  }) async {
    FirebaseFunctions functions = FirebaseFunctions.instance;
    if (_testing) {
      functions.useFunctionsEmulator(
        origin: 'http://localhost:$_functionsPort',
      );
    }

    final data = {
      FunctionParams.email: email,
      Info.item_name: username,
      Info.id: uid,
      FunctionParams.password: password,
    };
    try {
      await functions.httpsCallable("cu").call(data);
    } catch (e) {
      switch ((e as FirebaseFunctionsException).code) {
        case ErrorCodes.invalid_username:
          return CreateAccountResult.invalid_username;
        case ErrorCodes.invalid_email:
          return CreateAccountResult.invalid_email;
        case ErrorCodes.invalid_uid:
          return CreateAccountResult.invalid_uid;
        case ErrorCodes.invalid_pswd:
          return CreateAccountResult.invalid_pswd;
        case ErrorCodes.mission_failed:
          return CreateAccountResult.missionFailed;
        default:
          throw "unknown error code when creating user: \"${(e as FirebaseFunctionsException).code}\"";
      }
    }
    return CreateAccountResult.success;
  }
}
