// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:klang/constants/klang_constants.dart';
import 'package:klang/objects/klang_obj.dart';
import 'package:klang/objects/klang_sound.dart';
import 'package:klang/objects/klang_user.dart';

enum LoginResultMsg {
  success,
  invalid_email,
  wrong_password,
  user_disabled,
  user_not_found,
  network_request_failed,
}

enum CreateAccountResultMsg {
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

enum CreateSoundResultMsg {
  success,
  unsupported_file_extension,
  no_sound,
  file_too_big,
  unauthenticated,
  invalid_sound_name,
  mission_failed,
  internal,
}

enum SearchSoundHomeResultMsg {
  success,
  mission_failed,
  internal,
}

class SearchSoundHomeResult {
  SearchSoundHomeResult._(this.resultMsg, this.sounds);
  final SearchSoundHomeResultMsg resultMsg;
  final List<KlangSound> sounds;
}

enum SearchFromKeysResultMsg {
  success,
  mission_failed,
  internal,
}

class SearchFromKeysResult<O extends KlangObj> {
  SearchFromKeysResult._(this.resultMsg, this.items);
  final SearchFromKeysResultMsg resultMsg;
  final List<O> items;
}

/// combo between Firebase and HTTP
class FirePP {
  static final bool isTesting = true && kDebugMode;
  static final _authPort = "9099";
  static final _functionsPort = "5001";
  // ignore: unused_field
  static final _firestorePort = "8080";
  // ignore: unused_field
  static final _rtdbPort = "9000";
  // ignore: unused_field
  static final _hostingPort = "5000";
  static final storagePort = 9199;

  static String translateLoginMsg(LoginResultMsg l) {
    switch (l) {
      case LoginResultMsg.success:
        return "success";
      case LoginResultMsg.invalid_email:
        return "invalid email";
      case LoginResultMsg.wrong_password:
        return "wrong password";
      case LoginResultMsg.user_disabled:
        return "user not enabled";
      case LoginResultMsg.user_not_found:
        return "unknown email - it doesn't correspond to an existing user";
      case LoginResultMsg.network_request_failed:
        return "failed to send network request, make sure you're connected";
    }
    throw "unknow LoginResult: \"$l\"";
  }

  static String translateCreateAccountMsg(CreateAccountResultMsg c) {
    switch (c) {
      case CreateAccountResultMsg.success:
        return "success";
      case CreateAccountResultMsg.invalid_username:
        return "invalid username";
      case CreateAccountResultMsg.invalid_email:
        return "invalid email";
      case CreateAccountResultMsg.invalid_uid:
        return "invalid uid";
      case CreateAccountResultMsg.invalid_pswd:
        return "invalid password";
      case CreateAccountResultMsg.uid_taken:
        return "uid already in use";
      case CreateAccountResultMsg.email_taken:
        return "email already in use";
      case CreateAccountResultMsg.network_request_failed:
        return "failed to send network request, make sure you're connected";
      case CreateAccountResultMsg.missionFailed:
      case CreateAccountResultMsg.internal:
        return "something went wrong, please try again later or if you can, send us an email describing what went wrong and we'll try to fix it asap";
    }
    throw "unknown CreateAccountResult: \"$c\"";
  }

  static String translateCreateSoundMsg(CreateSoundResultMsg r) {
    switch (r) {
      case CreateSoundResultMsg.success:
        return "success - sound uploaded";
      case CreateSoundResultMsg.unsupported_file_extension:
        return "unsupported sound extension, supported extensions are: ${Lengths.supported_sound_file_extensions.join(", ")}";
      case CreateSoundResultMsg.no_sound:
        return "no sound file received";
      case CreateSoundResultMsg.file_too_big:
        return "file size is too big, max is ${Lengths.max_sound_file_size_bytes / 1000000} MB";
      case CreateSoundResultMsg.unauthenticated:
        return "user not authenticated";
      case CreateSoundResultMsg.invalid_sound_name:
        return "invalid sound name";
      case CreateSoundResultMsg.internal:
      case CreateSoundResultMsg.mission_failed:
        return "something failed, might have something to do with the sound file. If you can, send us an email with the sound attached and we'll investigate the problem. Feel free to include any other non-personal info that may be relevant.";
    }
    throw "unknown CreateSoundResult: \"$r\"";
  }

  static String translateSearchSoundHomeResultMsg(SearchSoundHomeResultMsg m) {
    switch (m) {
      case SearchSoundHomeResultMsg.success:
        return "success";
      case SearchSoundHomeResultMsg.internal:
      case SearchSoundHomeResultMsg.mission_failed:
        return "failed to load, retry?";
    }
    throw "unknown SearchSoundHomeResultMsg: \"m\"";
  }

  static String translateSearchFromKeysResultMsg(SearchFromKeysResultMsg m) {
    switch (m) {
      case SearchFromKeysResultMsg.success:
        return "success";
      case SearchFromKeysResultMsg.internal:
      case SearchFromKeysResultMsg.mission_failed:
        return "failed to load, retry?";
    }
    throw "unknown SearchFromKeysResultMsg: \"m\"";
  }

  /// returns [LoginResultMsg] to inform result
  static Future<LoginResultMsg> login({
    @required String email,
    @required String password,
  }) async {
    try {
      if (isTesting) {
        await FirebaseAuth.instance.useEmulator("http://localhost:$_authPort");
      }
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      switch ((e as FirebaseAuthException).code) {
        case "invalid-email":
          return LoginResultMsg.invalid_email;
        case "user-disabled":
          return LoginResultMsg.user_disabled;
        case "user-not-found":
          return LoginResultMsg.user_not_found;
        case "wrong-password":
          return LoginResultMsg.wrong_password;
        case "network-request-failed":
          return LoginResultMsg.network_request_failed;
        default:
          throw "unknown FirebaseAuthException error code: \"${(e as FirebaseAuthException).code}\"";
      }
    }
    return LoginResultMsg.success;
  }

  /// call http create account function
  /// returns [CreateAccountResultMsg] to inform result
  static Future<CreateAccountResultMsg> createAccount({
    @required String email,
    @required String username,
    @required String uid,
    @required String password,
  }) async {
    FirebaseFunctions functions = FirebaseFunctions.instance;
    if (isTesting) {
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
          return CreateAccountResultMsg.invalid_username;
        case ErrorCodes.invalid_email:
          return CreateAccountResultMsg.invalid_email;
        case ErrorCodes.invalid_uid:
          return CreateAccountResultMsg.invalid_uid;
        case ErrorCodes.invalid_pswd:
          return CreateAccountResultMsg.invalid_pswd;
        case ErrorCodes.uid_taken:
          return CreateAccountResultMsg.uid_taken;
        case ErrorCodes.mission_failed:
        case ErrorCodes.email_taken:
          return CreateAccountResultMsg.email_taken;
          return CreateAccountResultMsg.missionFailed;
        case ErrorCodes.internal:
          return CreateAccountResultMsg.internal;
        default:
          throw "create_user: unknown error code: \"${(e as FirebaseFunctionsException).message.toLowerCase()}\"";
      }
    }
    return CreateAccountResultMsg.success;
  }

  /// [name] - sound name
  /// [tags] (optional) - sound tags
  /// [description] (optional) - sound description
  /// [url] (optional) - sound source url if obtained from somewhere else
  /// [uid] - creator id
  /// [explicit] - whether sound is explicit
  /// [fileBytes] - sound file's bytes
  static Future<CreateSoundResultMsg> create_sound({
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

    if (isTesting) {
      storage.useEmulator(host: "localhost", port: storagePort);
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
          return CreateSoundResultMsg.unsupported_file_extension;
        case ErrorCodes.no_sound:
          return CreateSoundResultMsg.no_sound;
        case ErrorCodes.file_too_big:
          return CreateSoundResultMsg.file_too_big;
        case ErrorCodes.unauthenticated:
          return CreateSoundResultMsg.unauthenticated;
        case ErrorCodes.invalid_sound_name:
          return CreateSoundResultMsg.invalid_sound_name;
        case ErrorCodes.mission_failed:
        case ErrorCodes.internal:
          return CreateSoundResultMsg.mission_failed;
          break;
        default:
          debugPrint(
              "**create_sound: unknown error code: \"${(e as FirebaseFunctionsException).message.toLowerCase()}\"");
          return CreateSoundResultMsg.mission_failed;
      }
    }

    // FIXME: in firebase functions, need to set timeout & memory -> file processing could take bit longer than usual

    return CreateSoundResultMsg.success;
  }

  /// home page shows best or most downloaded sounds
  /// [metric] is either [Search.sub_type_best] or [Search.sub_type_downloads]
  /// [time] is a time period in [KlangTimePeriodArr]
  static Future<SearchSoundHomeResult> search_sounds_home({
    @required String metric,
    @required String time,
    @required List<dynamic> offset,
  }) async {
    assert(
      metric == Metrics.best || metric == Metrics.downloads,
    );
    assert(KlangTimePeriodArr.contains(time));

    FirebaseFunctions functions = FirebaseFunctions.instance;

    if (isTesting) {
      functions.useFunctionsEmulator(
        origin: "http://localhost:$_functionsPort",
      );
    }

    final data = {
      Search.type: Search.type_sound,
      Search.sub_type: metric,
      Search.time_period: time,
      Search.offset: offset,
    };

    try {
      final result = await functions.httpsCallable("s").call(data);
      List<KlangSound> sounds =
          KlangSound.fromJsonArr(result.data[FunctionResult.items] as List);
      return SearchSoundHomeResult._(
        SearchSoundHomeResultMsg.success,
        sounds,
      );
    } catch (e) {
      if (e is FirebaseFunctionsException) {
        switch (e.message.toLowerCase()) {
          case ErrorCodes.internal:
          case ErrorCodes.mission_failed:
            return SearchSoundHomeResult._(
              SearchSoundHomeResultMsg.internal,
              null,
            );
          default:
            debugPrint(
                "**search_sounds_home: unknown error code: \"${e.message.toLowerCase()}\"");
            return SearchSoundHomeResult._(
              SearchSoundHomeResultMsg.mission_failed,
              null,
            );
        }
      } else {
        // probably error parsing function data
        throw e;
      }
    }
  }

  static Future<SearchFromKeysResult<O>> search_from_str<O extends KlangObj>({
    @required String searchStr,
    List<dynamic> offset,
  }) async {
    FirebaseFunctions functions = FirebaseFunctions.instance;
    if (isTesting) {
      functions.useFunctionsEmulator(
        origin: "http://localhost:$_functionsPort",
      );
    }
    String contentType;
    if (O == KlangSound) {
      contentType = Search.type_sound;
    } else if (O == KlangUser) {
      contentType = Search.type_user;
    }
    final data = {
      Info.item_name: searchStr,
      Search.type: contentType,
      Search.sub_type: Search.sub_type_sk,
      Search.offset: offset,
    };

    try {
      final result = await functions.httpsCallable("s").call<Map>(data);
      List<O> items =
          KlangObj.fromJsonArr<O>(result.data[FunctionResult.items]);
      final obj =
          SearchFromKeysResult<O>._(SearchFromKeysResultMsg.success, items);
      return obj;
    } catch (e) {
      throw e;
    }
  }
}

class TestFirePP {
  static Future<void> create_test_sounds() async {
    if (!FirePP.isTesting) return;
    FirebaseFunctions functions = FirebaseFunctions.instance;
    functions.useFunctionsEmulator(
      origin: "http://localhost:${FirePP._functionsPort}",
    );

    await functions.httpsCallable("_cts").call();
    return;
  }
}
