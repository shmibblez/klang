import * as functions from "firebase-functions";
import {
  Coll,
  FunctionParams,
  Info,
  Lengths,
  Misc,
  Properties,
  StoragePaths,
} from "./constants/constants";
import * as admin from "firebase-admin";
import {
  isAuthorized as isAuthenticated,
  isDescriptionOk,
  isSoundExtensionOk,
  isSoundNameOk,
  isUrlOk,
} from "./field_checks";
import { FirestoreSound } from "./data_models/sound";
import { generateSoundId, tagsFromStr } from "./field_generators";
import {
  FileTooBigError,
  InvalidSoundNameError,
  MissionFailedError,
  NoSoundError,
  UnauthenticatedError,
  UnsupportedFileExtensionError,
} from "./constants/errors";
import { promises as fs } from "fs";
import { extname, join, sep } from "path";
// import { promisify } from "util";
import * as ffmpeg from "fluent-ffmpeg";
import { storage } from "firebase-admin";

/**
 *
 * TODO setup rules to only allow sound uploads to [uid]/[file_type]/[item_name]
 * TODO rules must enforce all doc field requirements, and users can only upload to their path, and there needs to be upload limits
 *
 * does stuff depending on file type uploaded
 * sound docs are created from fields in file metadata
 *
 * file categories - file paths organized so object can have multiple files associated, in case more needed in future
 * - sound file - [uid]/StoragePaths.sound/[sound_id]/[StoragePaths.sound_file_name].m4a
 * - user image - [uid]/StoragePaths.user/[StoragePaths.user_image_name].jpg
 * - list image - [uid]/StoragePaths.list/[list_id]/[StoragePaths.list_image_name].jpg
 *
 * general procedure
 * 1. surround whole function in try/catch, if anything fails delete file at path
 * 2. get content type from file path
 * 3. depending on file type, do stuff (check file type functions below)
 *
 * procedures for file categories in functions below:
 * - onSoundUpload
 * - ...
 * - ...
 */
export const create_sound = functions.https.onCall(async (data, context) => {
  const raw_ext = extname(data[FunctionParams.sound_file_name]);
  if (!isSoundExtensionOk(raw_ext)) throw new UnsupportedFileExtensionError();
  const raw_bytes: Uint8Array = data[FunctionParams.sound_file_bytes];
  if (raw_bytes == undefined) throw new NoSoundError();
  if (raw_bytes.byteLength > Lengths.max_sound_file_size_bytes)
    throw new FileTooBigError();

  if (!isAuthenticated(context)) throw new UnauthenticatedError();
  const uid = context.auth?.uid!;

  const raw_name: string = data[Info.item_name];
  if (!isSoundNameOk(raw_name)) throw new InvalidSoundNameError();
  // optional, only valid tags are added
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

  // TODO: check if user can add sound (upload limit not reached)

  // sound id follows format: [uid]+[name], where all chars in name that arent in [A-Za-z0-9-] are replaced with -
  const id: string = generateSoundId({ uid: uid, name: raw_name });

  const original_filepath = join(process.cwd(), id.replace("+", sep), raw_ext); // TODO: use sound id as filename in uid dir: "[uid]/[soundid].ext"
  const new_filepath = join(
    process.cwd(),
    id.replace("+", sep),
    Misc.storage_sound_file_ext
  );

  try {
    await fs.writeFile(original_filepath, raw_bytes);
  } catch (e) {
    // failed to write file
    await _fileCleanup();
    throw new MissionFailedError();
  }

  // not necessary since file size is checked anyway and encoded file is trimmed
  // const original_duration = await new Promise<number>((resolve, reject) =>
  //   ffmpeg.ffprobe(original_filepath, (err, data) => {
  //     if (err) {
  //       console.error(
  //         "create_sound: ffprobe failed on original sound file: ",
  //         err
  //       );
  //       throw new MissionFailedError();
  //     } else {
  //       const duration = data.format.duration;
  //       if (duration != undefined) resolve(duration);
  //       resolve(0);
  //     }
  //   })
  // );
  // if (original_duration > Lengths.max_sound_duration_millis) {
  //   throw new SoundDurationTooLongError();
  // }

  await new Promise<void>((resolve, reject) => {
    ffmpeg(original_filepath)
      .audioBitrate("128k")
      .audioChannels(2)
      .audioCodec(Misc.storage_sound_file_mime)
      .inputOption("-t 30")
      .saveToFile(new_filepath)
      .on("error", async (e) => {
        console.error(
          `create_sound: failed to convert file to ${Misc.storage_sound_file_ext}: `,
          e
        );
        await _fileCleanup();
        reject(new MissionFailedError());
      })
      .on("end", (stdout) => {
        console.log("create_sound: processed file, output: ", stdout);
        resolve();
      });
  });

  const storage_bucket = Misc.storage_bucket;
  // [uid]/StoragePaths.sound/[sound_id]/StoragePaths.sound_file_name.aac
  const storage_path = `${uid}/${StoragePaths.sound}/${id}/${StoragePaths.sound_file_name}${Misc.storage_sound_file_ext}`;

  await storage()
    .bucket(Misc.storage_bucket)
    .upload(new_filepath, { resumable: false, destination: storage_path })
    .catch(async (e) => {
      console.error(
        "create_sound: failed to upload sound file to storage: ",
        e
      );
      await _fileCleanup();
      throw new MissionFailedError();
    });

  // TODO: get file bytes, store in temp file, convert, compress, & trim, store in other temp file, upload to storage, clean up files (remove), then proceed.
  // If something fails report error

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
    fileBucket: storage_bucket,
    filePath: storage_path,
  });

  // create sound doc
  // if throws error sound file will be deleted anyway -> error will be caught by top-level try/catch
  try {
    await admin.firestore().doc(sound_doc_path).create(sound_doc_data);
  } catch (e) {
    // TODO: if id already taken, need to retry upload with uid generator. Move this to function that retries. Do this if it works so don't overcomplicate stuff too early
    console.log("file_uploaded: failed to create sound doc: ", e);
    await _fileCleanup();
    throw new MissionFailedError();
  }

  return Promise.resolve();

  async function _fileCleanup() {
    await fs.unlink(original_filepath);
    await fs.unlink(new_filepath);
  }
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
