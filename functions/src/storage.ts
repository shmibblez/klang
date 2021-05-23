import * as functions from "firebase-functions";
import { Coll, Info, Properties, StoragePaths } from "./constants/constants";
import * as admin from "firebase-admin";
import { isDescriptionOk, isUrlOk } from "./field_checks";
import { FirestoreSound } from "./data_models/sound";
import { tagsFromStr } from "./field_generators";
import { MissionFailedError } from "./constants/errors";

/**
 *
 * TODO: setup rules to only allow sound uploads to [uid]/[file_type]/[item_name]
 * TODO: rules must enforce all doc field requirements, and users can only upload to their path, and there needs to be upload limits
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
export const file_uploaded = functions.storage
  .object()
  .onFinalize(async (object) => {
    try {
      const [uid, file_type, id] = object.name?.split("/") ?? [];

      switch (file_type) {
        case StoragePaths.sound:
          await onSoundUpload(id, uid, object);
          break;

        case StoragePaths.user:
          // only user images allowed, but not ready yet
          await deleteFile();
          break;

        default:
          // should not happen, delete file
          console.error(
            'file_uploaded: unknown file type "' + file_type + '" received'
          );
          await deleteFile();
          break;
      }
    } catch (e) {
      await deleteFile();
      console.error("file_uploaded: something failed: ", e);
    }

    return Promise.resolve();

    /**
     * deletes file in case anything fails
     */
    async function deleteFile() {
      try {
        await admin.storage().bucket(object.bucket).file(object.name!).delete();
      } catch (e) {
        console.error("file_uploaded: failed to delete file: ", e);
      }
    }
  });

/**
 * procedure
 * 1. check params from metadata
 * 2.
 *
 * @param obj cloud storage obj
 */
async function onSoundUpload(
  id: string,
  uid: string,
  obj: functions.storage.ObjectMetadata
) {
  const raw_name: string = obj.metadata![Info.item_name];
  // comma separated tag strings, ex: ringtone,metronome sound,nice
  const raw_tags_str: string = obj.metadata![Info.tags] ?? "";
  const tags = tagsFromStr(raw_tags_str);
  // optional, if not ok then empty
  let raw_description: string | undefined = obj.metadata![Info.description];
  if (!isDescriptionOk(raw_description)) {
    raw_description = undefined;
  }
  // optional, if not ok then empty
  let raw_source_url: string | undefined = obj.metadata![Info.source_url];
  if (!isUrlOk(raw_source_url)) {
    raw_source_url = undefined;
  }
  // 1 or 0 string, defaults to true if other string
  const raw_explicit: boolean =
    obj.metadata![Properties.explicit] == "0" ? false : true;

  // remember: sounds don't store creator username, only creator uid

  const sound_doc_path = Coll.sounds + "/" + id;
  const sound_doc_data = FirestoreSound.initDocData({
    obj: obj,
    id: id,
    name: raw_name,
    tags: tags,
    description: raw_description,
    source_url: raw_source_url,
    creator_id: uid,
    explicit: raw_explicit,
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
}
