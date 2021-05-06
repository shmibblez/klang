import * as functions from "firebase-functions";
import { Info, Properties, StoragePaths } from "./constants/constants";
import * as admin from "firebase-admin";
import { isDescriptionOk, isUrlOk } from "./field_checks";
import { FirestoreSound } from "./data_models/sound";
import { tagsFromStr } from "./field_generators";

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
      const [uid, file_type] = object.name?.split("/") ?? [];

      switch (file_type) {
        case StoragePaths.sound:
          await onSoundUpload(uid, object);
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

    async function deleteFile() {
      // TODO: in case something goes wrong, delete file, make sure to catch & log error in case failed
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
  uid: string,
  obj: functions.storage.ObjectMetadata
) {
  // all data is already sanitized, was subject to storage rules check
  // TODO: some data is optional & can't be checked with regex in rules, like tags, so make sure to check those here & set default values in case don't pass checks
  //.
  // name is always ok
  const raw_name: string = obj.metadata![Info.item_name];
  // comma separated tag strings, ex: ringtone,metronome sound,nice
  const raw_tags_str: string = obj.metadata![Info.tags];
  const tags = tagsFromStr(raw_tags_str);
  let raw_description: string = obj.metadata![Info.description];
  if (!isDescriptionOk(raw_description)) {
    raw_description = ""; // TODO: set value to one that won't get stored in firestore, undefined maybe? (investigate or test later)
  }
  let raw_source_url: string = obj.metadata![Info.source_url];
  if (!isUrlOk(raw_source_url)) {
    raw_source_url = "";
  }
  // 1 or 0 string
  const raw_explicit: boolean =
    obj.metadata![Properties.explicit] == "0" ? false : true;

  // TODO: setup initDocData (currently returns empty obj)
  const sound_doc_data = FirestoreSound.initDocData({
    name: raw_name,
    tags: tags,
    description: raw_description,
    explicit: raw_explicit,
  });

  // remember: sounds don't store creator username, only creator uid
}
