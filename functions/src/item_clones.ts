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
  NotSavedError,
  UnauthenticatedError,
} from "./constants/errors";
import { FirestoreSound } from "./data_models/sound";
import { isAuthorized, isDocIdOk } from "./field_checks";

/**
 * steps:
 * 1. check if sound already saved, if yes throw error
 * 2. add sound to user's saved sounds doc
 * 3. add uid to clone doc, update sound data
 */
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
    .collection(Coll.user_saved)
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
    if (saved_sounds_snap.data()?.[Root.items]?.[sound_id] !== undefined)
      throw new AlreadySavedError();

    /// check if sound exists
    const sound_snap = await t.get(sound_doc_ref);
    if (!sound_snap.exists) throw new NonexistentDocError();
    let sound_doc_data = sound_snap.data()!;

    /// check if already saved in clone
    const impostor_docs = (await t.get(impostor_query)).docs;
    if (impostor_docs.length !== 0) throw new AlreadySavedError(); // impostor caught successfully

    // get available clone doc
    const available_clone_snaps = (await t.get(sound_doc_clones_query)).docs;

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
      // if does exist, update timestamp and add sound
      saved_sounds_data![Root.info][Info.timestamp_updated] =
        firestore.FieldValue.serverTimestamp();
      saved_sounds_data![Root.items][sound_id] =
        firestore.FieldValue.serverTimestamp();
      t.update(saved_sounds_ref, saved_sounds_data!);
    }

    /// add uid to available clone doc
    if (available_clone_snaps.length <= 0) {
      // if no available clones, create new one
      if (!sound_doc_data[Root.clone]) {
        sound_doc_data[Root.clone] = {};
      }

      const clone_num =
        (sound_doc_data[Root.clone][Clone.clone_count] as number) ?? 0;
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
      const clone_data = Object.assign({}, sound_doc_data);
      delete clone_data[Root.legal];
      delete clone_data[Root.clone];
      // add uid to clone
      clone_data[Root.clone] = {
        [Clone.ids]: [uid],
        [Clone.space_available]: true,
      };
      t.create(clone_ref, clone_data);
      /// increment clone count, set if doesn't exist
      if (sound_doc_data[Root.clone][Clone.clone_count] === undefined)
        sound_doc_data[Root.clone][Clone.clone_count] = 0;
      (sound_doc_data[Root.clone][Clone.clone_count] as number)++;
    } else {
      // if clone available, add uid and update
      const clone_data = available_clone_snaps[0].data()!;
      (clone_data[Root.clone][Clone.ids] as string[]).push(uid);
      if (
        (clone_data[Root.clone][Clone.ids] as string[]).length >=
        Lengths.max_clone_sound_uids
      ) {
        // if max uids reached, set [space_available] to false
        clone_data[Root.clone][Clone.space_available] = false;
      }
      const clone_ref = available_clone_snaps[0].ref;
      t.update(clone_ref, clone_data);
    }
    FirestoreSound.updateMetric({
      metric: Metrics.saves,
      data: sound_doc_data,
      change: +1,
    });
    t.update(sound_doc_ref, sound_doc_data);

    return Promise.resolve();
  });
});

// TODO: save except do the opposite
/**
 * steps:
 * 1. check if sound already saved, if yes throw error
 * 2. add sound to user's saved sounds doc
 * 3. add uid to clone doc, update sound data
 */
export const unsave_sound = functions.https.onCall(async (data, context) => {
  /// check params
  if (!isAuthorized(context)) throw new UnauthenticatedError();
  const uid = context.auth?.uid!;
  const sound_id = data[Info.id];
  if (!isDocIdOk(sound_id)) throw new InvalidDocIdError();

  /// setup queries
  // user's saved sounds doc
  const saved_sounds_ref = firestore()
    .collection(Coll.users)
    .doc(uid)
    .collection(Coll.user_saved)
    .doc(Docs.saved_sounds);
  // finds clone doc containing uid
  const clone_query = firestore()
    .collection(Coll.sounds)
    .doc(sound_id)
    .collection(Coll.saves)
    .where(`${Root.clone}.${Clone.ids}`, "array-contains", uid);
  // original sound doc
  const sound_doc_ref = firestore().collection(Coll.sounds).doc(sound_id);

  /// unsave sound if already saved
  await firestore().runTransaction(async (t) => {
    /// check user's saved sounds doc
    const saved_sounds_snap = await t.get(saved_sounds_ref);
    if (!saved_sounds_snap.exists) throw new NotSavedError(); // if user's saved sounds doc doesn't exist, then no saved sounds
    let saved_sounds_data = saved_sounds_snap.data()!;
    if (saved_sounds_data[Root.items]?.[sound_id] === undefined)
      throw new NotSavedError(); // if sound not saved

    /// get sound doc
    const sound_snap = await t.get(sound_doc_ref);

    /// if sound exists, update sound doc and clone doc, else, only remove from user's saved sounds doc
    if (sound_snap.exists) {
      let sound_doc_data = sound_snap.data()!;
      /// check if already saved
      const clone_snaps = (await t.get(clone_query)).docs;
      if (clone_snaps.length <= 0) throw new NotSavedError(); // if no clone found, not saved
      const clone_ref = clone_snaps[0].ref;
      /// remove uid from clone doc
      const clone_data = clone_snaps[0].data()!;
      // find indx of uid
      const uid_indx = (clone_data[Root.clone][Clone.ids] as string[]).indexOf(
        uid
      );
      // remove item at uid indx
      (clone_data[Root.clone][Clone.ids] as string[]).splice(uid_indx, 1);
      // set clone space available to true
      clone_data[Root.clone][Clone.space_available] = true;

      /// update sound metrics
      // TODO: read this over to see if all good
      FirestoreSound.updateMetric({
        metric: Metrics.saves,
        data: sound_doc_data,
        change: -1,
      });
      t.update(sound_doc_ref, sound_doc_data);
      t.update(clone_ref, clone_data);
    }

    /// remove sound from user's saved sounds doc
    saved_sounds_data![Root.info][Info.timestamp_updated] =
      firestore.FieldValue.serverTimestamp();
    delete saved_sounds_data![Root.items][sound_id];
    t.update(saved_sounds_ref, saved_sounds_data!);

    return Promise.resolve();
  });
});

export const on_sound_update = functions.firestore
  .document(`${Coll.sounds}/{docId}`)
  .onUpdate(async (snap, context) => {
    // check if has clones
    const numClones = snap.after.data()![Root.clone]?.[Clone.clone_count];
    console.log("on_sound_update: clone count: " + numClones);
    if (numClones === undefined || numClones <= 0) return Promise.resolve();

    // if has clones, update them
    const clones_query = firestore()
      .collection(Coll.sounds)
      .doc(snap.after.id)
      .collection(Coll.saves);

    // prepare data to copy to clones
    const sound_data = snap.after.data();
    const necessary_sound_data: { [k: string]: any } = {
      [Root.info]: sound_data[Root.info],
      [Root.properties]: sound_data[Root.properties],
      [Root.metrics]: sound_data[Root.metrics], // {} combined with below if too much storage
    };
    // only activate with above {} if too much storage
    // for (const k in sound_data[Root.metrics]) {
    //   // only keep total metrics
    //   if (k == Metrics.timestamp_soonest_stale) continue;
    //   necessary_sound_data[Root.metrics][k] = {
    //     [Metrics.total]: sound_data[Root.metrics][k][Metrics.total],
    //   };
    // }
    await firestore().runTransaction(async (t) => {
      const docs = (await t.get(clones_query)).docs;
      console.log("on_sound_update: doc count: " + docs.length);

      for (const d of docs) {
        const clone_data = d.data();
        // replace clone data with newest sound doc data
        Object.assign(clone_data, necessary_sound_data);
        t.update(d.ref, clone_data);
      }
      return Promise.resolve();
    });
  });
