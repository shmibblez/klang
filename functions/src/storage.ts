import * as functions from "firebase-functions";
import { Coll, FunctionParams, Info, Properties, StoragePaths } from "./constants/constants";
import * as admin from "firebase-admin";
import { isAuthorized as isAuthenticated, isDescriptionOk, isUrlOk } from "./field_checks";
import { FirestoreSound } from "./data_models/sound";
import { tagsFromStr } from "./field_generators";
import { MissionFailedError, NoSoundError, UnauthenticatedError } from "./constants/errors";
import * as fs from "fs"

export const createSound = functions.https.onCall(async (data, context) => {
  if(!isAuthenticated(context)) throw new UnauthenticatedError();

  const uid = context.auth?.uid;

  const raw_name: string = data[Info.item_name];
  const raw_tags_str: string = data[Info.tags] ?? "";
  const tags = tagsFromStr(raw_tags_str);
  // optional
  let raw_description: string | undefined = data[Info.description];
  if (!isDescriptionOk(raw_description)) {
    raw_description = undefined;
  }
  // optional, if not ok then empty
  let raw_source_url = data[Info.source_url];
  if (!isUrlOk(raw_source_url)) {
    raw_source_url == undefined;
  }
  // 1 or 0 string, defaults to true if other string
  let raw_explicit: boolean = data[Properties.explicit];
  if (typeof raw_explicit != "boolean") raw_explicit = true;

  const raw_bytes:Uint8Array = data[FunctionParams.sound_file_bytes];
  if(raw_bytes == undefined) throw new NoSoundError();

  
  // TODO: check if user can add sound (upload limit not reached)

  const original_filename = "file.mp3"; // TODO: send filename with extension in function params, and use here

  try {
   fs.writeFileSync(original_filename, raw_bytes);
  } catch (e) {
    // failed to write file
    throw new MissionFailedError();
  }


  // TODO: get file bytes, store in temp file, convert, compress, & trim, store in other temp file, upload to storage, clean up files (remove), then proceed.
  // If something fails report error



  const id:string = "";
  // TODO: generate sound doc id, should be combo between creator id and name: "[uid]+[name_with_invalid_chars_removed]"

  // for id, need to replace all characters in sound name that aren't alphanumeric with dash (with grapheme splitter, 
  // all graphemes that aren't in [A-Za-z-]), and add separator between uid and sound name (separator cannot be in valid characters for uid or sound name, for example "+")
  // also, for sound name, make kept name portion random between ex. 20-25, and make sure to call .toLowerCase()


  // set doc data
  const sound_doc_path = Coll.sounds + "/" + id;
  const sound_doc_data = FirestoreSound.initDocData({
    id: id,
    name: raw_name,
    tags: tags,
    description: raw_description,
    source_url: raw_source_url,
    creator_id: uid,
    explicit: raw_explicit,
    fileBucket: ,
    filePath: ,
  });

  // create sound doc
  // if throws error sound file will be deleted anyway -> error will be caught by top-level try/catch
  try {
    await admin.firestore().doc(sound_doc_path).create(sound_doc_data);
  } catch (e) {
    console.log("file_uploaded: failed to create sound doc: ", e);
    throw new MissionFailedError();
  }

  return Promise.resolve();
});
// /**
//  * procedure
//  * 1. check params from metadata
//  * 2.
//  *
//  * @param obj cloud storage obj
//  */
// async function onSoundUpload(
//   id: string,
//   uid: string,
//   obj: functions.storage.ObjectMetadata
// ) {
//   const raw_name: string = obj.metadata![Info.item_name];
//   // comma separated tag strings, ex: ringtone,metronome sound,nice
//   const raw_tags_str: string = obj.metadata![Info.tags] ?? "";
//   const tags = tagsFromStr(raw_tags_str);
//   // optional, if not ok then empty
//   let raw_description: string | undefined = obj.metadata![Info.description];
//   if (!isDescriptionOk(raw_description)) {
//     raw_description = undefined;
//   }
//   // optional, if not ok then empty
//   let raw_source_url: string | undefined = obj.metadata![Info.source_url];
//   if (!isUrlOk(raw_source_url)) {
//     raw_source_url = undefined;
//   }
//   // 1 or 0 string, defaults to true if other string
//   const raw_explicit: boolean =
//     obj.metadata![Properties.explicit] == "0" ? false : true;

//   // remember: sounds don't store creator username, only creator uid

//   const sound_doc_path = Coll.sounds + "/" + id;
//   const sound_doc_data = FirestoreSound.initDocData({
//     obj: obj,
//     id: id,
//     name: raw_name,
//     tags: tags,
//     description: raw_description,
//     source_url: raw_source_url,
//     creator_id: uid,
//     explicit: raw_explicit,
//   });

//   // create sound doc
//   // if throws error sound file will be deleted anyway -> error will be caught by top-level try/catch
//   try {
//     await admin.firestore().doc(sound_doc_path).create(sound_doc_data);
//   } catch (e) {
//     console.log("file_uploaded: failed to create sound doc: ", e);
//     throw new MissionFailedError();
//   }

//   return Promise.resolve();
// }

// /**
//  *
//  * TODO: setup rules to only allow sound uploads to [uid]/[file_type]/[item_name]
//  * TODO: rules must enforce all doc field requirements, and users can only upload to their path, and there needs to be upload limits
//  *
//  * does stuff depending on file type uploaded
//  * sound docs are created from fields in file metadata
//  *
//  * file categories - file paths organized so object can have multiple files associated, in case more needed in future
//  * - sound file - [uid]/StoragePaths.sound/[sound_id]/[StoragePaths.sound_file_name].m4a
//  * - user image - [uid]/StoragePaths.user/[StoragePaths.user_image_name].jpg
//  * - list image - [uid]/StoragePaths.list/[list_id]/[StoragePaths.list_image_name].jpg
//  *
//  * general procedure
//  * 1. surround whole function in try/catch, if anything fails delete file at path
//  * 2. get content type from file path
//  * 3. depending on file type, do stuff (check file type functions below)
//  *
//  * procedures for file categories in functions below:
//  * - onSoundUpload
//  * - ...
//  * - ...
//  */
// export const file_uploaded = functions.storage
//   .object()
//   .onFinalize(async (object) => {
//     try {
//       const [uid, file_type, id] = object.name?.split("/") ?? [];

//       switch (file_type) {
//         case StoragePaths.sound:
//           await onSoundUpload(id, uid, object);
//           break;

//         case StoragePaths.user:
//           // only user images allowed, but not ready yet
//           await deleteFile();
//           break;

//         default:
//           // should not happen, delete file
//           console.error(
//             'file_uploaded: unknown file type "' + file_type + '" received'
//           );
//           await deleteFile();
//           break;
//       }
//     } catch (e) {
//       await deleteFile();
//       console.error("file_uploaded: something failed: ", e);
//     }

//     return Promise.resolve();

//     /**
//      * deletes file in case anything fails
//      */
//     async function deleteFile() {
//       try {
//         await admin.storage().bucket(object.bucket).file(object.name!).delete();
//       } catch (e) {
//         console.error("file_uploaded: failed to delete file: ", e);
//       }
//     }
//   });

// /**
//  * procedure
//  * 1. check params from metadata
//  * 2.
//  *
//  * @param obj cloud storage obj
//  */
// async function onSoundUpload(
//   id: string,
//   uid: string,
//   obj: functions.storage.ObjectMetadata
// ) {
//   const raw_name: string = obj.metadata![Info.item_name];
//   // comma separated tag strings, ex: ringtone,metronome sound,nice
//   const raw_tags_str: string = obj.metadata![Info.tags] ?? "";
//   const tags = tagsFromStr(raw_tags_str);
//   // optional, if not ok then empty
//   let raw_description: string | undefined = obj.metadata![Info.description];
//   if (!isDescriptionOk(raw_description)) {
//     raw_description = undefined;
//   }
//   // optional, if not ok then empty
//   let raw_source_url: string | undefined = obj.metadata![Info.source_url];
//   if (!isUrlOk(raw_source_url)) {
//     raw_source_url = undefined;
//   }
//   // 1 or 0 string, defaults to true if other string
//   const raw_explicit: boolean =
//     obj.metadata![Properties.explicit] == "0" ? false : true;

//   // remember: sounds don't store creator username, only creator uid

//   const sound_doc_path = Coll.sounds + "/" + id;
//   const sound_doc_data = FirestoreSound.initDocData({
//     obj: obj,
//     id: id,
//     name: raw_name,
//     tags: tags,
//     description: raw_description,
//     source_url: raw_source_url,
//     creator_id: uid,
//     explicit: raw_explicit,
//   });

//   // create sound doc
//   // if throws error sound file will be deleted anyway -> error will be caught by top-level try/catch
//   try {
//     await admin.firestore().doc(sound_doc_path).create(sound_doc_data);
//   } catch (e) {
//     console.log("file_uploaded: failed to create sound doc: ", e);
//     throw new MissionFailedError();
//   }

//   return Promise.resolve();
// }
