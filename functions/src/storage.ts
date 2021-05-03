import * as functions from "firebase-functions";
import { Info, Properties } from "./constants/constants";
import { InvalidUsernameError } from "./constants/errors";
import { isUsernameOk } from "./field_checks";
import * as admin from "firebase-admin";

/**
 *
 * TODO: setup rules to only allow sound uploads to [uid]/[file_type]/[item_name]
 * TODO: [file_type] in above path can be "sound", "user_image", or "list_image"
 * TODO: rules must enforce all doc field requirements, and users can only upload to their path, and there needs to be upload limits
 *
 * does stuff depending on file type uploaded
 * sound docs are created from fields in file metadata
 *
 * file categories
 * - sound file
 * - user image
 * - list image
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
        case "sound": // TODO: add storage path constants, remove string literal
          await onSoundUpload(uid, object);
          break;
      }
    } catch (e) {
      // in case something goes wrong, delete file
      //TODO
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
  const raw_name = obj.metadata?.[Info.item_name];
  const raw_tags = obj.metadata?.[Info.tags];
  const raw_description = obj.metadata?.[Info.description];
  const raw_source_url = obj.metadata?.[Info.source_url];
  const raw_creator_id = obj.metadata?.[Info.creator_id];
  const explicit = obj.metadata?.[Properties.explicit];

  // remember: sounds don't store creator username, only creator uid
}
