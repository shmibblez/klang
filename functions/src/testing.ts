import { firestore } from "firebase-admin";
import * as functions from "firebase-functions";
import { Coll, Info, Metrics, Properties, Root } from "./constants/constants";
import * as rw from "random-words";
import {
  generateSoundId,
  indexName,
  indexProperties,
  indexTags,
  randomSeeds,
} from "./field_generators";

export const create_test_sounds = functions.https.onCall(
  async (data, context) => {
    // only run if testing
    if (process.env.FUNCTIONS_EMULATOR && process.env.FIRESTORE_EMULATOR_HOST) {
      const promises: Promise<any>[] = [];
      const numSounds = 5;
      const uid = "shmibblez";
      const fileBucket = "klang-7.appspot.com";

      for (let i = 0; i < numSounds; i++) {
        const name = rw({ min: 2, max: 4, join: " " });
        const sound_id = generateSoundId({ name: name });
        const tags = rw({ min: 1, max: 3 });
        const description = rw({ min: 3, max: 25, join: " " });
        const source_url = "";
        const explicit = false;
        const filePath = "test_sound.aac"; //`${StoragePaths.sounds}/${uid}/${sound_id}/${StoragePaths.sound_file_name}${Misc.storage_sound_file_ext}`;

        const data = {
          [Root.info]: {
            [Info.id]: sound_id,
            [Info.item_name]: {
              [Info.item_name]: name,
              [Info.search_keys]: indexName(name),
              [Info.timestamp_updated]: firestore.FieldValue.serverTimestamp(),
            },
            [Info.tags]: tags,
            [Info.tag_keys]: indexTags(tags),
            [Info.description]: description,
            [Info.source_url]: source_url ?? undefined,
            [Info.creator_id]: uid,
            [Info.timestamp_created]: firestore.FieldValue.serverTimestamp(),
            [Info.timestamp_updated]: firestore.FieldValue.serverTimestamp(),
            [Info.storage]: {
              [Info.audio_file_bucket]: fileBucket, // obj.bucket,
              [Info.audio_file_path]: filePath, // obj.name,
              [Info.audio_file_duration]: 7 * 1000, // 7 seconds to millis
            },
          },
          [Root.properties]: {
            [Properties.explicit]: explicit,
            [Properties.hidden]: false,
            [Properties.search_keys]: indexProperties(explicit, false),
            [Properties.random_seeds]: randomSeeds(),
          },
          [Root.metrics]: {
            [Metrics.downloads]: _randomizeMetrics(),
            [Metrics.saves]: _randomizeMetrics(),
            [Metrics.best]: _randomizeMetrics(),
            [Metrics.parent_lists]: _randomizeMetrics(),
          },
          // no metrics when created
          // no legal info when created
        };

        promises.push(
          firestore().collection(Coll.sounds).doc(sound_id).create(data)
        );
      }
      await Promise.all(promises);
    }

    return Promise.resolve();
  }
);

function _randomizeMetrics(): { [k: string]: number } {
  const randNum = () => Math.trunc(Math.random() * 1000000.0);
  return {
    [Metrics.total]: randNum(),
    [Metrics.this_day]: randNum(),
    [Metrics.this_week]: randNum(),
    [Metrics.this_month]: randNum(),
    [Metrics.this_year]: randNum(),
    [Metrics.this_decade]: randNum(),
    [Metrics.this_century]: randNum(),
    [Metrics.this_millenium]: randNum(),
  };
}
