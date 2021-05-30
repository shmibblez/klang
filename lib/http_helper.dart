// ignore_for_file: non_constant_identifier_names

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
  uid_taken,
  email_taken,
  missionFailed,
  internal,
  network_request_failed,
}

enum CreateSoundResult {
  success,
  unsupported_file_extension,
  no_sound,
  file_too_big,
  unauthenticated,
  invalid_sound_name,
  mission_failed,
}

enum QueryResult {
  unsupported_query,
  no_more_items,
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
      case CreateAccountResult.uid_taken:
        return "uid already in use";
      case CreateAccountResult.email_taken:
        return "email already in use";
      case CreateAccountResult.network_request_failed:
        return "failed to send network request, make sure you're connected";
      case CreateAccountResult.missionFailed:
      case CreateAccountResult.internal:
        return "something went wrong, please try again later or if you can, send us an email describing what went wrong and we'll try to fix it asap";
    }
    throw "unknown CreateAccountResult: \"$c\"";
  }

  static String translateCreateSoundResult(CreateSoundResult r) {
    switch (r) {
      case CreateSoundResult.success:
        return "success - sound uploaded";
      case CreateSoundResult.unsupported_file_extension:
        return "unsupported sound extension, supported extensions are: ${Lengths.supported_sound_file_extensions.join(", ")}";
      case CreateSoundResult.no_sound:
        return "no sound file received";
      case CreateSoundResult.file_too_big:
        return "file size is too big, max is ${Lengths.max_sound_file_size_bytes / 1000000} MB";
      case CreateSoundResult.unauthenticated:
        return "user not authenticated";
      case CreateSoundResult.invalid_sound_name:
        return "invalid sound name";
      case CreateSoundResult.mission_failed:
        return "something failed, might have something to do with the sound file. If you can, send us an email with the sound attached and we'll investigate the problem. Feel free to include any other non-personal info that may be relevant.";
    }
    throw "unknown CreateSoundResult: \"$r\"";
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
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
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
      switch ((e as FirebaseFunctionsException).message.toLowerCase()) {
        case ErrorCodes.invalid_username:
          return CreateAccountResult.invalid_username;
        case ErrorCodes.invalid_email:
          return CreateAccountResult.invalid_email;
        case ErrorCodes.invalid_uid:
          return CreateAccountResult.invalid_uid;
        case ErrorCodes.invalid_pswd:
          return CreateAccountResult.invalid_pswd;
        case ErrorCodes.uid_taken:
          return CreateAccountResult.uid_taken;
        case ErrorCodes.mission_failed:
        case ErrorCodes.email_taken:
          return CreateAccountResult.email_taken;
          return CreateAccountResult.missionFailed;
        case ErrorCodes.internal:
          return CreateAccountResult.internal;
        default:
          throw "create_user: unknown error code: \"${(e as FirebaseFunctionsException).message.toLowerCase()}\"";
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
  static Future<CreateSoundResult> create_sound({
    @required String name,
    @required Set<String> tags,
    @required String description,
    @required String url,
    @required bool explicit,
    @required Uint8List fileBytes,
    @required String fileName,
  }) async {
    FirebaseStorage storage = FirebaseStorage.instance;
    FirebaseFunctions functions = FirebaseFunctions.instance;

    if (_testing) {
      storage.useEmulator(host: "localhost", port: _storagePort);
      functions.useFunctionsEmulator(
        origin: "http://localhost:$_functionsPort",
      );
    }

    final data = {
      Info.item_name: name,
      Info.tags: tags.join(","),
      Info.description: description,
      Info.source_url: url,
      Properties.explicit: explicit,
      FunctionParams.sound_file_bytes: fileBytes,
      FunctionParams.sound_file_name: fileName,
    };

    try {
      await functions.httpsCallable("cs").call(data);
    } catch (e) {
      switch ((e as FirebaseFunctionsException).message.toLowerCase()) {
        case ErrorCodes.unsupported_file_extension:
          return CreateSoundResult.unsupported_file_extension;
        case ErrorCodes.no_sound:
          return CreateSoundResult.no_sound;
        case ErrorCodes.file_too_big:
          return CreateSoundResult.file_too_big;
        case ErrorCodes.unauthenticated:
          return CreateSoundResult.unauthenticated;
        case ErrorCodes.invalid_sound_name:
          return CreateSoundResult.invalid_sound_name;
        case ErrorCodes.mission_failed:
        case ErrorCodes.internal:
          return CreateSoundResult.mission_failed;
          break;
        default:
          debugPrint(
              "**create_sound: unknown error code: \"${(e as FirebaseFunctionsException).message.toLowerCase()}\"");
          return CreateSoundResult.mission_failed;
      }
    }

    // FIXME: in firebase functions, need to set timeout & memory -> file processing could take bit longer than usual

    return CreateSoundResult.success;
  }

  static Future<QueryResult> search({
    @required String queryType,
    @required String querySubType,
    @required Map<String, dynamic> data,
  }) async {
    // TODO:
  }
}
