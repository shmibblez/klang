import { Root, Info, Properties, Username } from "../constants/constants";
import {
  indexName,
  indexProperties,
  randomSeeds,
} from "../field_generators";
import * as admin from "firebase-admin";

// utility class for firestore username docs
export class FirestoreUsername {
  // generates initial username doc data
  static initDocData({
    uid,
    username,
  }: {
    uid: string;
    username: string;
  }): { [k: string]: unknown } {
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
  static initDocData({
    uid,
    username,
  }: {
    uid: string;
    username: string;
  }): { [k: string]: unknown } {
    return {
      [Root.info]: {
        [Info.id]: uid,
        [Info.item_name]: {
          [Info.item_name]: username,
          [Info.search_keys]: indexName(username),
          [Info.timestamp_updated]: admin.firestore.FieldValue.serverTimestamp(),
        },
        [Info.timestamp_created]: admin.firestore.FieldValue.serverTimestamp(),
        [Info.timestamp_updated]: admin.firestore.FieldValue.serverTimestamp(),
      },
      [Root.properties]: {
        [Properties.explicit]: false,
        [Properties.hidden]: false,
        [Properties.search_keys]: indexProperties(false, false),
        [Properties.random_seeds]: randomSeeds(),
      },
    };
  }
}
