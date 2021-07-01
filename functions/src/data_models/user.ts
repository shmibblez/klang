import {
  Root,
  Info,
  Properties,
  Username,
  Metrics,
  Misc,
} from "../constants/constants";
import {
  indexName,
  indexProperties,
  initMetric,
  randomSeeds,
} from "../field_generators";
import * as admin from "firebase-admin";

// utility class for firestore username docs
export class FirestoreUsername {
  // generates initial username doc data
  static initDocData({ uid, username }: { uid: string; username: string }): {
    [k: string]: unknown;
  } {
    return { [Username.username]: username, [Username.uid]: uid };
  }
}

// utility class for user firestore follower docs
export class FirestoreFollower {
  // generates inital follower doc data
  static initDocData(): { [k: string]: unknown } {
    // TODO:
    return {};
  }
}

// utility class for firestore user docs
export class FirestoreUser {
  // generates initial user doc data
  static initDocData({ uid, username }: { uid: string; username: string }): {
    [k: string]: unknown;
  } {
    return {
      [Root.info]: {
        [Info.id]: uid,
        [Info.item_name]: {
          [Info.item_name]: username,
          [Info.search_keys]: indexName(username),
          [Info.timestamp_updated]:
            admin.firestore.FieldValue.serverTimestamp(),
        },
        [Info.tags]: [Misc.wildcard_str],
        [Info.tag_keys]: [Misc.wildcard_str],
        [Info.tag_history]: { [Misc.wildcard_str]: 0 },
        [Info.timestamp_created]: admin.firestore.FieldValue.serverTimestamp(),
        [Info.timestamp_updated]: admin.firestore.FieldValue.serverTimestamp(),
      },
      [Root.properties]: {
        [Properties.explicit]: false,
        [Properties.hidden]: false,
        [Properties.search_keys]: indexProperties(false, false),
        [Properties.random_seeds]: randomSeeds(),
      },
      [Root.metrics]: {
        [Metrics.best]: initMetric(),
        [Metrics.followers]: initMetric(),
        [Metrics.following]: initMetric(),
        [Metrics.sounds_created]: initMetric(),
        [Metrics.lists_created]: initMetric(),
      },
    };
  }
}
