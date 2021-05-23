import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:klang/constants/transpiled_constants.dart';

enum LoginResult {
  success,
  invalid_email,
  wrong_password,
  user_disabled,
  user_not_found,
  network_request_failed,
}

enum CreateAccountResult {
  success,
  invalid_username,
  invalid_email,
  invalid_uid,
  invalid_pswd,
  missionFailed,
  internal,
  network_request_failed,
}

enum AddSoundResult {
  success,
  access_denied,
  lost_connection,
  upload_failed,
}

/// combo between Firebase and HTTP
class FirePP {
  static final bool _testing = true && kDebugMode;
  static final _authPort = "9099";
  static final _functionsPort = "5001";
  static final _firestorePort = "8080";
  static final _rtdbPort = "9000";
  static final _hostingPort = "5000";
  static final _storagePort = 9199;

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
      case LoginResult.network_request_failed:
        return "failed to send network request, make sure you're connected";
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
      case CreateAccountResult.network_request_failed:
        return "failed to send network request, make sure you're connected";
      case CreateAccountResult.missionFailed:
      case CreateAccountResult.internal:
        return "something went wrong, please try again later or if you can, send us an email describing what went wrong and we'll try to fix it asap";
    }
    throw "unknown CreateAccountResult: \"$c\"";
  }

  /// returns [LoginResult] to inform result
  static Future<LoginResult> login({
    @required String email,
    @required String password,
  }) async {
    try {
      if (_testing) {
        await FirebaseAuth.instance.useEmulator("http://localhost:$_authPort");
      }
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
        case "wrong-password":
          return LoginResult.wrong_password;
        case "network-request-failed":
          return LoginResult.network_request_failed;
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
      debugPrint("*received error: $e");
      switch ((e as FirebaseFunctionsException).message) {
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
        case ErrorCodes.internal:
          return CreateAccountResult.internal;
        default:
          throw "unknown error code when creating user: \"${(e as FirebaseFunctionsException).message}\"";
      }
    }
    return CreateAccountResult.success;
  }

  /// [name] - sound name
  /// [tags] (optional) - sound tags
  /// [description] (optional) - sound description
  /// [url] (optional) - sound source url if obtained from somewhere else
  /// [uid] - creator id
  /// [explicit] - whether sound is explicit
  /// [fileBytes] - sound file's bytes
  static Future<AddSoundResult> addSound({
    @required String name,
    @required Set<String> tags,
    @required String description,
    @required String url,
    @required String uid,
    @required bool explicit,
    @required Uint8List fileBytes,
  }) async {
    FirebaseStorage storage = FirebaseStorage.instance;

    if (_testing) {
      storage.useEmulator(host: "localhost", port: _storagePort);
    }

    // TODO: upload sound here

    // TODO: compress file bytes / convert to .m4a 248 kbps, or just make sure file type valid, and edit when storage function called
    // if going to edit, convert, or compress audio file in storage functions, need to set config for longer time & more storage ->
    // need to make sure function can store sound file, temp (2x file size at least), and process doesn't get killed (at least 10 secs? need to check how long it takes to modify audio file)

    // this means storage function will now:
    // 1. make sure all fields good
    // 2. modify audio file (convert to m4a, compress, cut if over max sound length)
    // 3. add firestore doc
    // if anything fails, how to inform user?
    //    Potential solution: client-side add task that checks if sound doc exists after some seconds (if upload success), if it does, then show snackbar informing success, if not, show snackbar with error. How to get error?
    //    Potential solution 2: send notification to user device informing result, here can easily report error reason or success, and can even show notification if user left app after upload
    //.

    // FIXME: instead of doing above, can do everything in firebase function:
    // 1. check user upload status / limits
    // 1.1 check if fields valid
    // 2. convert bytes to file, then process with ffmpeg, then add to storage
    // 2.1 check if audio file valid (length, size, etc)
    // 3. if file upload success, then add sound doc
    // - using this approach, if there's an error, appropriate message will be thrown
    // - no need to send notification to inform result
    //
    //.
    // storage.ref().put

    return AddSoundResult.success;
  }
}
