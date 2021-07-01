// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
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

enum SearchItemResultMsg {
  success,
  mission_failed,
  internal,
}

class SearchItemResult<O extends KlangObj> {
  SearchItemResult._(this.resultMsg, this.item);
  final SearchItemResultMsg resultMsg;
  final O item;
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

enum GetSavedItemsResultMsg { success, mission_failed, internal }

class GetSavedItemsResult {
  GetSavedItemsResult._(this.resultMsg, this.items);
  final GetSavedItemsResultMsg resultMsg;
  final List<Map<String, Timestamp>> items;
}

enum SaveSoundResultMsg {
  success,
  unauthenticated,
  invalid_sound_id,
  limit_overflow,
  already_saved,
  nonexistent_sound,
  mission_failed,
  internal,
}

enum UnsaveSoundResultMsg {
  success,
  unauthenticated,
  invalid_sound_id,
  not_saved,
  mission_failed,
  internal,
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

  static String translateSaveSoundResultMsg(SaveSoundResultMsg r) {
    switch (r) {
      case SaveSoundResultMsg.success:
        return "saved sound successfully";
      case SaveSoundResultMsg.unauthenticated:
        return "need to be signed in to save sound";
      case SaveSoundResultMsg.invalid_sound_id:
        return "sound id provided is invalid";
      case SaveSoundResultMsg.limit_overflow:
        return "saved sound limit has been reached, you can only save 100 sounds";
      case SaveSoundResultMsg.already_saved:
        return "this sound's already been saved";
      case SaveSoundResultMsg.nonexistent_sound:
        return "sound doesn't exist anymore";
      case SaveSoundResultMsg.internal:
      case SaveSoundResultMsg.mission_failed:
        return "something failed on our end, if you can, please send us the sound id you're trying to save";
    }
    throw "unknown SaveSoundResultMsg: \"$r\"";
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
    assert(KlangTimePeriods.contains(time));

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

  static Future<SearchItemResult<O>> search_item<O extends KlangObj>({
    @required String itemId,
    bool isOwner = false,
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
      Info.id: itemId,
      Search.type: contentType,
      Search.sub_type: Search.sub_type_item,
      // if explicit ok, true since need to get user profile
      Properties.explicit: true,
    };
    try {
      final result = await functions.httpsCallable("s").call(data);
      final rawItem = result.data[FunctionResult.items];
      List<O> itemArr = KlangObj.fromJsonArr<O>(rawItem);
      O i = itemArr.isEmpty ? null : itemArr[0];
      return SearchItemResult<O>._(SearchItemResultMsg.success, i);
    } catch (e) {
      debugPrint("***error: $e");
      if (e is FirebaseFunctionsException) {
        switch (e.message.toLowerCase()) {
          case ErrorCodes.mission_failed:
            return SearchItemResult<O>._(
              SearchItemResultMsg.mission_failed,
              null,
            );
          case ErrorCodes.internal:
            debugPrint(
                "**search_sounds_home: unknown error code: \"${e.message.toLowerCase()}\"");
            return SearchItemResult<O>._(
              SearchItemResultMsg.mission_failed,
              null,
            );
          default:
            throw "this shouldn't happen";
        }
      } else {
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

  /// returns list of saved items: [saved sounds, saved lists]
  static Future<GetSavedItemsResult> getSavedItems() async {
    FirebaseFunctions functions = FirebaseFunctions.instance;
    if (isTesting) {
      functions.useFunctionsEmulator(
        origin: "http://localhost:$_functionsPort",
      );
    }
    // TODO: get from local storage, also check if has local list, if no list cached, then force_query should be true
    Timestamp timestampSoundsLastUpdated;
    final data = {
      FunctionParams.timestamp: {
        FunctionParams.timestamp_seconds:
            timestampSoundsLastUpdated?.seconds ?? 0,
        FunctionParams.timestamp_nanoseconds:
            timestampSoundsLastUpdated?.nanoseconds ?? 0,
      },
      FunctionParams.force_sound_query:
          true, // TODO: true if no local list found
    };
    try {
      final result =
          await functions.httpsCallable("gsi").call<Map<String, dynamic>>(data);
      final saved_sounds_doc = result.data[FunctionResult.sounds];
      if (saved_sounds_doc == null)
        return GetSavedItemsResult._(GetSavedItemsResultMsg.success, [{}]);

      final raw_sounds = saved_sounds_doc[Root.items] as Map<String, dynamic>;
      final sounds = Map<String, Timestamp>();

      raw_sounds.forEach((key, value) {
        final seconds = value["_seconds"];
        final nanoseconds = value["_nanoseconds"];
        sounds[key] = Timestamp(seconds, nanoseconds);
      });

      // TODO: save local version of saved sounds list here (use pub package localstorage), also save timestamp last updated

      return GetSavedItemsResult._(GetSavedItemsResultMsg.success, [sounds]);
    } catch (e) {
      throw e;
    }
  }

  static Future<SaveSoundResultMsg> saveSound(String soundId) async {
    FirebaseFunctions functions = FirebaseFunctions.instance;
    if (isTesting) {
      functions.useFunctionsEmulator(
        origin: "http://localhost:$_functionsPort",
      );
    }
    final data = {
      Info.id: soundId,
    };
    try {
      await functions.httpsCallable("ss").call(data);
      return SaveSoundResultMsg.success;
    } catch (e) {
      if (e is FirebaseFunctionsException) {
        switch (e.message.toLowerCase()) {
          case ErrorCodes.unauthenticated:
            return SaveSoundResultMsg.unauthenticated;
          case ErrorCodes.invalid_doc_id:
            return SaveSoundResultMsg.invalid_sound_id;
          case ErrorCodes.limit_overflow:
            return SaveSoundResultMsg.limit_overflow;
          case ErrorCodes.already_saved:
            return SaveSoundResultMsg.already_saved;
          case ErrorCodes.nonexistent_doc:
            return SaveSoundResultMsg.nonexistent_sound;
          case ErrorCodes.internal:
          case ErrorCodes.mission_failed:
            return SaveSoundResultMsg.mission_failed;
          default:
            debugPrint(
                "**search_sounds_home: unknown error code: \"${e.message.toLowerCase()}\"");
            throw e;
        }
      } else {
        throw e;
      }
    }
  }

  static Future<UnsaveSoundResultMsg> unsaveSound(String soundId) async {
    FirebaseFunctions functions = FirebaseFunctions.instance;
    if (isTesting) {
      functions.useFunctionsEmulator(
        origin: "http://localhost:$_functionsPort",
      );
    }
    final data = {
      Info.id: soundId,
    };
    try {
      await functions.httpsCallable("us").call(data);
      return UnsaveSoundResultMsg.success;
    } catch (e) {
      if (e is FirebaseFunctionsException) {
        switch (e.message.toLowerCase()) {
          case ErrorCodes.unauthenticated:
            return UnsaveSoundResultMsg.unauthenticated;
          case ErrorCodes.invalid_doc_id:
            return UnsaveSoundResultMsg.invalid_sound_id;
          case ErrorCodes.not_saved:
            return UnsaveSoundResultMsg.not_saved;
          case ErrorCodes.internal:
          case ErrorCodes.mission_failed:
            return UnsaveSoundResultMsg.mission_failed;
          default:
            debugPrint(
                "**search_sounds_home: unknown error code: \"${e.message.toLowerCase()}\"");
            throw e;
        }
      } else {
        throw e;
      }
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
