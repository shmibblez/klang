import { firestore } from "firebase-admin";
import * as functions from "firebase-functions";
import {
  Clone,
  Coll,
  Docs,
  Info,
  Lengths,
  Metrics,
  Root,
} from "./constants/constants";
import {
  AlreadySavedError,
  InvalidDocIdError,
  LimitOverflowError,
  NonexistentDocError,
  UnauthenticatedError,
} from "./constants/errors";
import { FirestoreSound } from "./data_models/sound";
import { isAuthorized, isDocIdOk } from "./field_checks";

export const save_sound = functions.https.onCall(async (data, context) => {
  /// check params
  if (!isAuthorized(context)) throw new UnauthenticatedError();
  const uid = context.auth?.uid!;
  const sound_id = data[Info.id];
  if (!isDocIdOk(sound_id)) throw new InvalidDocIdError();

  /// setup queries
  // gets docs that have space in id list
  const sound_doc_clones_query = firestore()
    .collection(Coll.sounds)
    .doc(sound_id)
    .collection(Coll.saves)
    .where(`${Root.clone}.${Clone.space_available}`, "==", true)
    .limit(1);
  // finds doc that already contains uid
  const impostor_query = firestore()
    .collection(Coll.sounds)
    .doc(sound_id)
    .collection(Coll.saves)
    .where(`${Root.clone}.${Clone.ids}`, "array-contains", sound_id);
  // original sound doc
  const sound_doc_ref = firestore().collection(Coll.sounds).doc(sound_id);
  // user's saved sounds doc
  const saved_sounds_ref = firestore()
    .collection(Coll.users)
    .doc(uid)
    .collection(Coll.saved)
    .doc(Docs.saved_sounds);

  /// save sound if not already saved
  await firestore().runTransaction(async (t) => {
    /// check user's saved sounds doc
    const saved_sounds_snap = await t.get(saved_sounds_ref);
    let saved_sounds_data = saved_sounds_snap.data();
    // check if save limit reached
    if (
      Object.keys(saved_sounds_data?.[Root.items] ?? {}).length >=
      Lengths.max_saved_sounds
    )
      throw new LimitOverflowError();
    // check if already saved
    if (saved_sounds_snap.data()![Root.items][sound_id] !== undefined)
      throw new AlreadySavedError();

    /// check if sound exists
    const sound_snap = await t.get(sound_doc_ref);
    if (!sound_snap.exists) throw new NonexistentDocError();
    let sound_doc_data = sound_snap.data()!;

    /// check if already saved
    const impostor_docs = (await t.get(impostor_query)).docs;
    if (impostor_docs.length !== 0) throw new AlreadySavedError(); // impostor caught successfully

    /// add sound to user's saved sounds doc
    if (!saved_sounds_snap.exists) {
      // if doesn't exist, create doc
      saved_sounds_data = {
        [Root.info]: {
          [Info.timestamp_updated]: firestore.FieldValue.serverTimestamp(),
          [Info.timestamp_checked]: firestore.FieldValue.serverTimestamp(),
        },
        [Root.items]: {
          [sound_id]: firestore.FieldValue.serverTimestamp(),
        },
      };
      t.create(saved_sounds_ref, saved_sounds_data);
    } else {
      // if does exist, update data
      saved_sounds_data![Root.info][Info.timestamp_updated] =
        firestore.FieldValue.serverTimestamp();
      saved_sounds_data![Root.items][sound_id] =
        firestore.FieldValue.serverTimestamp();
      t.update(saved_sounds_ref, saved_sounds_data!);
    }

    /// add uid to available clone doc
    const available_clone_snaps = (await t.get(sound_doc_clones_query)).docs;
    let clone_data: { [k: string]: any };
    if (available_clone_snaps.length <= 0) {
      // if no available clones, create new one
      const clone_num = sound_doc_data[Root.clone][Clone.clone_count] as number;
      const clone_id = FirestoreSound.formatSaveCloneId(
        sound_snap.id,
        clone_num
      );
      const clone_ref = firestore()
        .collection(Coll.sounds)
        .doc(sound_id)
        .collection(Coll.saves)
        .doc(clone_id);
      // setup clone data
      clone_data = Object.assign({}, sound_doc_data);
      delete clone_data[Root.legal];
      delete clone_data[Root.clone];
      // add uid to clone
      clone_data[Root.clone] = {
        [Clone.ids]: [uid],
        [Clone.space_available]: true,
      };
      t.create(clone_ref, clone_data);
      // set new clone as available & increment clone count
      (sound_doc_data[Root.clone][Clone.available_clone_ids] as string[]).push(
        clone_id
      );
      (sound_doc_data[Root.clone][Clone.clone_count] as number)++;
    } else {
      // if clone available, add uid and modify
      clone_data = available_clone_snaps[0].data()!;
      (clone_data[Root.clone][Clone.ids] as string[]).push(sound_id);
      if (
        (clone_data[Root.clone][Clone.ids] as string[]).length >=
        Lengths.max_clone_sound_uids
      ) {
        // if max uids reached, set [space_available] to false
        clone_data[Root.clone][Clone.space_available] = false;
        const indx = (
          sound_doc_data[Root.clone][Clone.available_clone_ids] as string[]
        ).indexOf(available_clone_snaps[0].id);
        // remove clone from available clones
        (
          sound_doc_data[Root.clone][Clone.available_clone_ids] as string[]
        ).splice(indx, 1);
      }
    }
    // TODO: read this over to see if all good
    // TODO: this updates main sound doc data, how/when to update clones?
    FirestoreSound.updateMetric({
      metric: Metrics.saves,
      data: sound_doc_data,
      change: +1,
    });
    t.update(sound_doc_ref, sound_doc_data);

    return Promise.resolve();
  });
});
