import { firestore } from "firebase-admin";
import { https } from "firebase-functions";
import {
  Properties,
  Search,
  SearchParamValues,
  Info,
  Coll,
  Root,
} from "./constants/constants";

export const search = https.onCall(async (data, context) => {
  // TODO: need to implement offset, check ringfone for this
  const search_type = data[Search.type];
  const limit = 20;
  const offset = data[Search.offset_id];
  let query: firestore.Query;
  switch (search_type) {
    case SearchParamValues.search_type_user:
      query = await userSearch(data);
      break;

    case SearchParamValues.search_type_sound:
    default:
      query = await soundSearch(data);
  }
  query = query.limit(15);
  let docs = (await query.get()).docs;
  docs.map((doc) => doc.data);
});

async function soundSearch(data: any): Promise<firestore.Query> {
  // TODO: checkout how you did this in ringfone
  // also need to check possible sound queries
  const explicit_ok = data[Properties.explicit] == true ? true : false;
  const explicit_property = explicit_ok
    ? Properties.explicit_and_not_hidden
    : Properties.not_explicit_and_not_hidden;
  const sub_type = data[Search.sub_type];
  let query: firestore.Query = firestore().collection(Coll.sounds);
  switch (sub_type) {
    case Search.sub_type_best:
      break;

    case Search.sub_type_downloads:
      break;

    case Search.sub_type_sk:
      const name = data[Info.item_name] ?? "";
      const keys = searchKeys(name);
      for (const k of keys) {
        query = query.where(
          `${Root.info}.${Info.name}.${Info.search_keys}.${k}`,
          "==",
          true
        );
      }
      query = query.where(
        `${Root.properties}.${Properties.search_keys}`,
        "==",
        explicit_property
      );
      break;

    case Search.sub_type_random:
    default:
      let seed_num = data[Search.random_seed_num] ?? 0;
      if (typeof seed_num != "number" || seed_num < 0 || seed_num > 4)
        seed_num = 0;
      let direction = data[Search.direction];
      if (
        direction != SearchParamValues.direction_asc &&
        direction != SearchParamValues.direction_dsc
      )
        direction = SearchParamValues.direction_dsc;
      query = query.orderBy(
        `${Root.properties}.${Properties.random_seeds}.${seed_num}`
      );
      query = query.where(
        `${Root.properties}.${Properties.search_keys}`,
        "==",
        explicit_property
      );
      break;
  }
  return query;
}

async function userSearch(data: any): Promise<firestore.Query> {
  let query: firestore.Query;
  // TODO:
  query = undefined;
  return query;
}

/**
 *
 * @param name sound name
 * @returns search keys for item name
 */
function searchKeys(name: unknown): string[] {
  if (typeof name != "string" || name.length <= 0) return [""];

  const indx = new Set();

  // TODO: split graphemes and pair up here

  return Array.from(indx) as string[];
}
