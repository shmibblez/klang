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
import { promises as fsPromises } from "fs";
import { extname, join } from "path";
// import { promisify } from "util";
import * as ffmpeg_static from "ffmpeg-static";
import * as ffmpeg from "fluent-ffmpeg";
import { firestore, storage } from "firebase-admin";

/**
 *
 * TODO block storage rules completely
 * TODO need to add upload limits
 *
 * does stuff depending on file type uploaded
 * sound docs are created from fields in file metadata
 *
 * file categories - file paths organized so object can have multiple files associated, in case more needed in future
 * - sound file - [StoragePaths.sounds]/[uid]/[sound_id]/[StoragePaths.sound_file_name].aac
 * - user image - [StoragePaths.users]/[uid]/[StoragePaths.user_image_name].jpg
 * - list image - [StoragePaths.lists]/[uid]/[list_id]/[StoragePaths.list_image_name].jpg
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
  /**
   * {@link phase_1 check & setup params}
   */
  if (!isAuthenticated(context)) throw new UnauthenticatedError();
  const uid = context.auth?.uid!;
  const raw_ext = extname(data[FunctionParams.sound_file_name]);
  if (!isSoundExtensionOk(raw_ext)) throw new UnsupportedFileExtensionError();
  const raw_bytes = new Uint8Array(data[FunctionParams.sound_file_bytes]);
  if (raw_bytes == undefined) throw new NoSoundError();
  if (raw_bytes.byteLength > Lengths.max_sound_file_size_bytes)
    throw new FileTooBigError();
  const raw_name: string = data[Info.item_name];
  if (!isSoundNameOk(raw_name)) throw new InvalidSoundNameError();
  const raw_tags_str: string = data[Info.tags] ?? ""; // optional, only valid tags are added
  const tags = tagsFromStr(raw_tags_str);
  let raw_description: string | undefined = data[Info.description]; // optional
  if (!isDescriptionOk(raw_description)) {
    raw_description = undefined;
  }
  let raw_source_url = data[Info.source_url]; // optional, if not ok then empty
  if (!isUrlOk(raw_source_url)) {
    raw_source_url == undefined;
  }
  let raw_explicit: boolean = data[Properties.explicit] == false ? false : true; // defaults to true if invalid value received

  // TODO: check user upload limits, could cache uids in case spam so don't read docs a lot
  //.

  // sound id is clean version of [name], where all chars in name that arent in [A-Za-z0-9-] are replaced with -
  let sound_id: string = generateSoundId({ name: raw_name });

  const clean_sound_name = sound_id.substring(sound_id.indexOf("+") + 1);
  const sound_file_dir = join(process.cwd(), uid);
  const input_filepath = join(sound_file_dir, clean_sound_name + raw_ext); // TODO: use sound id as filename in uid dir: "[uid]/[soundid].ext"
  const output_filepath = join(
    sound_file_dir,
    clean_sound_name + Misc.storage_sound_file_ext // for testing: + "2" + raw_ext
  );
  console.log(
    `create_sound:\n  input file: ${input_filepath}\n  output file: ${output_filepath}`
  );

  /**
   * {@link phase_2 write file}
   */
  try {
    try {
      await fsPromises.access(sound_file_dir);
    } catch (e) {
      await fsPromises.mkdir(sound_file_dir);
    }
    await fsPromises.writeFile(input_filepath, raw_bytes);
  } catch (e) {
    // failed to write file
    console.error("create_sound: failed to write file, error: ", e);
    await _fileCleanup();
    throw new MissionFailedError(e);
  }

  /**
   * {@link phase_3 process file with ffmpeg
   * - set codec to aac
   * - set bitrate to 128kbps
   * - set to 2 audio audioChannels
   * - cut to 30s max
   * - save locally to temp file
   * }
   */
  await new Promise<void>((resolve, reject) => {
    ffmpeg(input_filepath)
      .setFfmpegPath(ffmpeg_static)
      .inputOptions(["-analyzeduration 20M", "-probesize 20M"])
      .audioCodec(Misc.storage_sound_file_mime)
      .audioBitrate("128k")
      .audioChannels(2)
      .inputOption("-t 30")
      .saveToFile(output_filepath)
      // .on("start", (cmd) => {
      //   console.llog("beginning ffmpeg command, \ncmd: " + cmd);
      // })
      .on("error", async (e, stdout, stderr) => {
        console.error(
          `create_sound: failed to convert file to ${Misc.storage_sound_file_ext}: `,
          e
        );
        console.error("create_sound: stderr: ", stderr);
        await _fileCleanup();
        reject(new MissionFailedError(e));
      })
      .on("end", (stdout) => {
        console.log("create_sound: processed file, output: ", stdout);
        resolve();
      });
  });

  /**
   * {@link phase_3 create sound doc}
   */
  const storage_bucket = Misc.storage_bucket;
  // [StoragePaths.sounds]/[uid]/[sound_id]/[StoragePaths.sound_file_name].aac
  const storage_path = `${StoragePaths.sounds}/${uid}/${sound_id}/${StoragePaths.sound_file_name}${Misc.storage_sound_file_ext}`;
  let tries = 0;
  async function createSoundDoc({
    recreate_sound_id,
  }: {
    recreate_sound_id: boolean;
  }): Promise<firestore.DocumentReference> {
    if (tries >= 2) {
      await _fileCleanup();
      throw new MissionFailedError();
    }
    tries++;

    if (recreate_sound_id) {
      sound_id = generateSoundId({
        name: raw_name,
        randomize_end: true,
      });
    }
    console.log(`create_sound: generated sound id: ${sound_id}`);
    // set doc data
    const sound_doc_ref = admin.firestore().doc(Coll.sounds + "/" + sound_id);
    const sound_doc_data = FirestoreSound.initDocData({
      id: sound_id,
      name: raw_name,
      tags: tags,
      description: raw_description,
      source_url: raw_source_url,
      creator_id: uid,
      explicit: raw_explicit,
      fileBucket: storage_bucket,
      filePath: storage_path,
    });

    console.log(
      `create_sound: generated sound id after setting doc data: ${sound_id}`
    );
    // create sound doc
    try {
      await sound_doc_ref.create(sound_doc_data);
      return sound_doc_ref;
    } catch (e) {
      switch (e.code) {
        // if doc already exists, retry with different sound id
        case "already-exists":
          return await createSoundDoc({ recreate_sound_id: true });
      }
      console.error("file_uploaded: failed to create sound doc: ", e);
      await _fileCleanup();
      throw new MissionFailedError(e);
    }
  }
  const created_sound_doc_ref = await createSoundDoc({
    recreate_sound_id: false,
  });

  /**
   * {@link phase_4 upload sound file}
   */
  await storage()
    .bucket(Misc.storage_bucket)
    .upload(output_filepath, { resumable: false, destination: storage_path })
    .catch(async (e) => {
      console.error(
        "create_sound: failed to upload sound file to storage: ",
        e
      );
      try {
        await created_sound_doc_ref.delete();
      } catch (e) {
        // this is not good!!!
        console.error(
          `create_sound: failed to delete sound doc (id: ${sound_id}) after failed to upload file, e: `,
          e
        );
      }
      await _fileCleanup();
      throw new MissionFailedError(e);
    });

  /**
   * {@link phase_5 terminate operation}
   */

  return Promise.resolve();

  async function _fileCleanup() {
    try {
      await fsPromises.unlink(input_filepath);
    } catch (e) {
      console.error("create_sound: failed to delete original file, e: ", e);
    }
    try {
      await fsPromises.unlink(output_filepath);
    } catch (e) {
      console.error("create_sound: failed to delete processed file, e: ", e);
    }
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
//     console.error("file_uploaded: failed to create sound doc: ", e);
//     throw new MissionFailedError(e);
//   }

//   return Promise.resolve();
// }

// /**
//  *
//  * TODO: rules must enforce all doc field requirements, and users can only upload to their path, and there needs to be upload limits
//  *
//  * does stuff depending on file type uploaded
//  * sound docs are created from fields in file metadata
//  *
//  * file categories - file paths organized so object can have multiple files associated, in case more needed in future
//  * - sound file - StoragePaths.sounds/[uid]/[sound_id]/[StoragePaths.sound_file_name].aac
//  * - user image - StoragePaths.users/[uid]/[StoragePaths.user_image_name].jpg
//  * - list image - StoragePaths.lists/[uid]/[list_id]/[StoragePaths.list_image_name].jpg
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
//         case StoragePaths.sounds:
//           await onSoundUpload(id, uid, object);
//           break;

//         case StoragePaths.users:
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
//     console.error("file_uploaded: failed to create sound doc: ", e);
//     throw new MissionFailedError(e);
//   }

//   return Promise.resolve();
// }
