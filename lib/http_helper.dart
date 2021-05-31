// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:klang/constants/klang_constants.dart';
import 'package:klang/objects/klang_sound.dart';

enum LoginResultMessage {
  success,
  invalid_email,
  wrong_password,
  user_disabled,
  user_not_found,
  network_request_failed,
}

enum CreateAccountResultMessage {
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

enum CreateSoundResultMessage {
  success,
  unsupported_file_extension,
  no_sound,
  file_too_big,
  unauthenticated,
  invalid_sound_name,
  mission_failed,
  internal,
}

enum SearchSoundHomeResultMessage {
  success,
  mission_failed,
  internal,
}

class SearchSoundHomeResult {
  SearchSoundHomeResult._(this.resultMsg, this.sounds);
  final SearchSoundHomeResultMessage resultMsg;
  final List sounds;
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

  static String translateLoginResult(LoginResultMessage l) {
    switch (l) {
      case LoginResultMessage.success:
        return "success";
      case LoginResultMessage.invalid_email:
        return "invalid email";
      case LoginResultMessage.wrong_password:
        return "wrong password";
      case LoginResultMessage.user_disabled:
        return "user not enabled";
      case LoginResultMessage.user_not_found:
        return "unknown email - it doesn't correspond to an existing user";
      case LoginResultMessage.network_request_failed:
        return "failed to send network request, make sure you're connected";
    }
    throw "unknow LoginResult: \"$l\"";
  }

  static String translateCreateAccountResult(CreateAccountResultMessage c) {
    switch (c) {
      case CreateAccountResultMessage.success:
        return "success";
      case CreateAccountResultMessage.invalid_username:
        return "invalid username";
      case CreateAccountResultMessage.invalid_email:
        return "invalid email";
      case CreateAccountResultMessage.invalid_uid:
        return "invalid uid";
      case CreateAccountResultMessage.invalid_pswd:
        return "invalid password";
      case CreateAccountResultMessage.uid_taken:
        return "uid already in use";
      case CreateAccountResultMessage.email_taken:
        return "email already in use";
      case CreateAccountResultMessage.network_request_failed:
        return "failed to send network request, make sure you're connected";
      case CreateAccountResultMessage.missionFailed:
      case CreateAccountResultMessage.internal:
        return "something went wrong, please try again later or if you can, send us an email describing what went wrong and we'll try to fix it asap";
    }
    throw "unknown CreateAccountResult: \"$c\"";
  }

  static String translateCreateSoundResult(CreateSoundResultMessage r) {
    switch (r) {
      case CreateSoundResultMessage.success:
        return "success - sound uploaded";
      case CreateSoundResultMessage.unsupported_file_extension:
        return "unsupported sound extension, supported extensions are: ${Lengths.supported_sound_file_extensions.join(", ")}";
      case CreateSoundResultMessage.no_sound:
        return "no sound file received";
      case CreateSoundResultMessage.file_too_big:
        return "file size is too big, max is ${Lengths.max_sound_file_size_bytes / 1000000} MB";
      case CreateSoundResultMessage.unauthenticated:
        return "user not authenticated";
      case CreateSoundResultMessage.invalid_sound_name:
        return "invalid sound name";
      case CreateSoundResultMessage.internal:
      case CreateSoundResultMessage.mission_failed:
        return "something failed, might have something to do with the sound file. If you can, send us an email with the sound attached and we'll investigate the problem. Feel free to include any other non-personal info that may be relevant.";
    }
    throw "unknown CreateSoundResult: \"$r\"";
  }

  /// returns [LoginResultMessage] to inform result
  static Future<LoginResultMessage> login({
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
          return LoginResultMessage.invalid_email;
        case "user-disabled":
          return LoginResultMessage.user_disabled;
        case "user-not-found":
          return LoginResultMessage.user_not_found;
        case "wrong-password":
          return LoginResultMessage.wrong_password;
        case "network-request-failed":
          return LoginResultMessage.network_request_failed;
        default:
          throw "unknown FirebaseAuthException error code: \"${(e as FirebaseAuthException).code}\"";
      }
    }
    return LoginResultMessage.success;
  }

  /// call http create account function
  /// returns [CreateAccountResultMessage] to inform result
  static Future<CreateAccountResultMessage> createAccount({
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
          return CreateAccountResultMessage.invalid_username;
        case ErrorCodes.invalid_email:
          return CreateAccountResultMessage.invalid_email;
        case ErrorCodes.invalid_uid:
          return CreateAccountResultMessage.invalid_uid;
        case ErrorCodes.invalid_pswd:
          return CreateAccountResultMessage.invalid_pswd;
        case ErrorCodes.uid_taken:
          return CreateAccountResultMessage.uid_taken;
        case ErrorCodes.mission_failed:
        case ErrorCodes.email_taken:
          return CreateAccountResultMessage.email_taken;
          return CreateAccountResultMessage.missionFailed;
        case ErrorCodes.internal:
          return CreateAccountResultMessage.internal;
        default:
          throw "create_user: unknown error code: \"${(e as FirebaseFunctionsException).message.toLowerCase()}\"";
      }
    }
    return CreateAccountResultMessage.success;
  }

  /// [name] - sound name
  /// [tags] (optional) - sound tags
  /// [description] (optional) - sound description
  /// [url] (optional) - sound source url if obtained from somewhere else
  /// [uid] - creator id
  /// [explicit] - whether sound is explicit
  /// [fileBytes] - sound file's bytes
  static Future<CreateSoundResultMessage> create_sound({
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
          return CreateSoundResultMessage.unsupported_file_extension;
        case ErrorCodes.no_sound:
          return CreateSoundResultMessage.no_sound;
        case ErrorCodes.file_too_big:
          return CreateSoundResultMessage.file_too_big;
        case ErrorCodes.unauthenticated:
          return CreateSoundResultMessage.unauthenticated;
        case ErrorCodes.invalid_sound_name:
          return CreateSoundResultMessage.invalid_sound_name;
        case ErrorCodes.mission_failed:
        case ErrorCodes.internal:
          return CreateSoundResultMessage.mission_failed;
          break;
        default:
          debugPrint(
              "**create_sound: unknown error code: \"${(e as FirebaseFunctionsException).message.toLowerCase()}\"");
          return CreateSoundResultMessage.mission_failed;
      }
    }

    // FIXME: in firebase functions, need to set timeout & memory -> file processing could take bit longer than usual

    return CreateSoundResultMessage.success;
  }

  /// home page shows best or most downloaded sounds
  /// [metric] is either [Search.sub_type_best] or [Search.sub_type_downloads]
  /// [time] is a time period in [KlangTimePeriodArr]
  static Future<SearchSoundHomeResult> search_sounds_home({
    @required String metric,
    @required String time,
    @required Map<String, dynamic> data,
  }) async {
    assert(
      metric == Search.sub_type_best || metric == Search.sub_type_downloads,
    );
    assert(KlangTimePeriodArr.contains(time));

    FirebaseFunctions functions = FirebaseFunctions.instance;

    if (_testing) {
      functions.useFunctionsEmulator(
        origin: "http://localhost:$_functionsPort",
      );
    }

    final data = {
      Search.type: Search.type_sound,
      Search.sub_type: metric,
      Search.time_period: time,
    };

    try {
      final result = await functions.httpsCallable("s").call<List>(data);
      List<KlangSound> sounds = KlangSound.fromJsonArr(result.data);

      return SearchSoundHomeResult._(
        SearchSoundHomeResultMessage.success,
        sounds,
      );
    } catch (e) {
      switch ((e as FirebaseFunctionsException).message.toLowerCase()) {
        case ErrorCodes.internal:
        case ErrorCodes.mission_failed:
          return SearchSoundHomeResult._(
            SearchSoundHomeResultMessage.internal,
            null,
          );
        default:
          debugPrint(
              "**search_sounds_home: unknown error code: \"${(e as FirebaseFunctionsException).message.toLowerCase()}\"");
          return SearchSoundHomeResult._(
            SearchSoundHomeResultMessage.mission_failed,
            null,
          );
      }
    }
  }
}

class TestFirePP {
  static Future<void> create_test_sounds() async {
    if (!FirePP._testing) return;
    FirebaseFunctions functions = FirebaseFunctions.instance;
    functions.useFunctionsEmulator(
      origin: "http://localhost:${FirePP._functionsPort}",
    );

    await functions.httpsCallable("_cts").call();
    return;
  }
}
