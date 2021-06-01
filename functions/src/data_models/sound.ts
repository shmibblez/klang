import { Info, Metrics, Properties, Root } from "../constants/constants";
import {
  indexName,
  indexProperties,
  indexTags,
  initMetric,
  randomSeeds,
} from "../field_generators";
import * as admin from "firebase-admin";

export class FirestoreSound {
  // generates initial sound doc data
  static initDocData({
    // obj,
    id,
    name,
    tags,
    description,
    source_url,
    creator_id,
    explicit,
    fileBucket,
    filePath,
  }: {
    // obj: functions.storage.ObjectMetadata;
    id: string;
    name: string;
    tags: string[];
    description: string | undefined;
    source_url: string | undefined;
    creator_id: string;
    explicit: boolean;
    fileBucket: string;
    filePath: string;
  }): { [k: string]: unknown } {
    return {
      [Root.info]: {
        [Info.id]: id,
        [Info.item_name]: {
          [Info.item_name]: name,
          [Info.search_keys]: indexName(name),
          [Info.timestamp_updated]:
            admin.firestore.FieldValue.serverTimestamp(),
        },
        [Info.tags]: tags,
        [Info.tag_keys]: indexTags(tags),
        [Info.description]: description ?? "",
        [Info.source_url]: source_url ?? "",
        [Info.creator_id]: creator_id,
        [Info.timestamp_created]: admin.firestore.FieldValue.serverTimestamp(),
        [Info.timestamp_updated]: admin.firestore.FieldValue.serverTimestamp(),
        [Info.storage]: {
          [Info.audio_file_bucket]: fileBucket, // obj.bucket,
          [Info.audio_file_path]: filePath, // obj.name,
        },
      },
      [Root.properties]: {
        [Properties.explicit]: explicit,
        [Properties.hidden]: false,
        [Properties.search_keys]: indexProperties(explicit, false),
        [Properties.random_seeds]: randomSeeds(),
      },
      [Root.metrics]: {
        [Metrics.downloads]: initMetric(),
        [Metrics.saves]: initMetric(),
        [Metrics.best]: initMetric(),
        [Metrics.parent_lists]: initMetric(),
      },
      // no metrics when created
      // no legal info when created
    };
  }
}
