import { firestore } from "firebase-admin";
import * as functions from "firebase-functions";
import { Coll } from "./constants/constants";
import { FirestoreSound } from "./data_models/sound";
import * as rw from "random-words";
import { generateSoundId } from "./field_generators";

export const create_test_sounds = functions.https.onCall(
  async (data, context) => {
    // only run if testing
    if (process.env.FUNCTIONS_EMULATOR && process.env.FIRESTORE_EMULATOR_HOST) {
      const promises: Promise<any>[] = [];
      const numSounds = 50;

      for (let i = 0; i < numSounds; i++) {
        const name = rw({ min: 2, max: 4, join: " " });
        const sound_id = generateSoundId({ name: name });
        const data = FirestoreSound.initDocData({
          id: sound_id,
          name: name,
          tags: rw({ min: 1, max: 3 }),
          description: rw({ min: 3, max: 25, join: " " }),
          source_url: undefined,
          creator_id: "shmibblez",
          explicit: false,
          fileBucket: "",
          filePath: "",
        });
        promises.push(
          firestore().collection(Coll.sounds).doc(sound_id).create(data)
        );
      }
      await Promise.all(promises);
    }

    return Promise.resolve();
  }
);
