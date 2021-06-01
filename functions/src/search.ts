import { firestore } from "firebase-admin";
import { https } from "firebase-functions";
import {
  Properties,
  Search,
  Info,
  Coll,
  Root,
  Lengths,
  Misc,
  KlangTimePeriod,
  KlangTimePeriodArr,
  Metrics,
  FieldMasks,
  FunctionResult,
} from "./constants/constants";
import { UnsupportedQueryError } from "./constants/errors";
import { isTagOk } from "./field_checks";

export const search = https.onCall(async (data, context) => {
  const search_type = data[Search.type];
  const limit = 20;
  const coll = _collectionFrom(search_type);
  const fieldMask = _fieldMaskFrom(search_type);

  let query: firestore.Query;

  // since all doc types have same doc structure, can reuse types. Still need to check if type - sub-type pair is valid, since users can't have downloads for example
  query = await _itemSearch({ data: data, coll: coll, fieldMask: fieldMask });
  query = query.limit(limit);

  const snap = await query.get();
  return {
    [FunctionResult.items]: snap.docs.map<firestore.DocumentData>((doc) =>
      doc.data()
    ),
  };
});

async function _itemSearch({
  data,
  coll,
  fieldMask,
}: {
  data: any;
  coll: string;
  fieldMask: string[];
}): Promise<firestore.Query> {
  const explicit_ok = data[Properties.explicit] == true ? true : false;
  const explicit_property = explicit_ok
    ? Properties.explicit_and_not_hidden
    : Properties.not_explicit_and_not_hidden;
  const tags_sk = _tagsSearchKey(data[Info.tags]);
  const sub_type = data[Search.sub_type];
  const offset = data[Search.offset];

  let query: firestore.Query = firestore().collection(coll);

  // set explicit & tag filters (common for all user/sound/list queries)
  query = query.where(
    `${Root.properties}.${Properties.search_keys}`,
    "==",
    explicit_property
  );
  query = query.where(
    `${Root.info}.${Info.tag_keys}`,
    "array-contains",
    tags_sk ?? Misc.wildcard_str
  );

  console.log("search: tags_sk: " + tags_sk);

  switch (sub_type) {
    case Search.sub_type_downloads:
    case Search.sub_type_best:
      const time_period = _timePeriodFrom(data[Search.time_period]);
      const metric = _metricFrom(sub_type);
      /**
       *  explicit & tag filters already set
       **/
      console.log(
        "search: metric: " + metric + ", time period: " + time_period
      );
      query = query.orderBy(`${Root.metrics}.${metric}.${time_period}`, "desc");
      query = query.orderBy(firestore.FieldPath.documentId(), "asc");
      if (Array.isArray(offset) && offset.length == 2) {
        // offset should be ["metric count for time period", "doc id"]
        query = query.startAfter(...offset);
      }
      break;

    case Search.sub_type_sk:
      const name = data[Info.item_name] ?? "";
      const keys = _searchKeysFrom(name);
      /**
       *  explicit & tag filters already set
       **/
      if (keys.length > 99) keys.length = 99;
      for (const k of keys) {
        query = query.where(
          `${Root.info}.${Info.item_name}.${Info.search_keys}.${k}`,
          "==",
          true
        );
      }
      query = query.orderBy(firestore.FieldPath.documentId(), "asc");
      if (Array.isArray(offset) && offset.length == 1) {
        // offset should be ["doc id"]
        query = query.startAfter(...offset);
      }
      break;

    case Search.sub_type_random:
      let seed_num = data[Search.random_seed_num] ?? 0;
      if (typeof seed_num != "number" || seed_num < 0 || seed_num > 4)
        seed_num = 0;
      let direction = _directionFrom(data[Search.direction]);
      /**
       *  explicit & tag filters already set
       **/
      query = query.orderBy(
        `${Root.properties}.${Properties.random_seeds}.${seed_num}`,
        direction
      );
      query = query.orderBy(firestore.FieldPath.documentId(), "asc");
      if (Array.isArray(offset) && offset.length == 2) {
        // offset should be ["random seed value", "doc id"]
        query = query.startAfter(...offset);
      }
      break;
    default:
      throw new UnsupportedQueryError();
  }
  query = query.select(...fieldMask);
  return query;
}

/**
 *
 * @param name sound name
 * @returns search keys for item name
 */
function _searchKeysFrom(name: unknown): string[] {
  if (typeof name != "string" || name.length <= 0) return [""];

  const indx = new Set();

  // TODO: split graphemes and pair up here

  return Array.from(indx) as string[];
}

function _tagsSearchKey(tag_str: string): string {
  if (typeof tag_str != "string") return Misc.wildcard_str;

  let tags = tag_str.split(",");
  if (tags.length > Lengths.max_sound_tags)
    tags.length = Lengths.max_sound_tags;

  tags = tags.filter((tag) => isTagOk(tag));
  tags = tags.sort((a, b) => a.localeCompare(b, "en-US"));

  if (tags.length <= 0) return Misc.wildcard_str;

  let str = "";
  for (const t of tags) str += t + "|";
  str.substring(0, str.length - 2);

  return str;
}

function _directionFrom(d: string): FirebaseFirestore.OrderByDirection {
  if (d != Search.direction_asc && d != Search.direction_desc) {
    return Search.direction_desc;
  }
  return d;
}

function _timePeriodFrom(t: string): KlangTimePeriod {
  if (!KlangTimePeriodArr.includes(t as KlangTimePeriod))
    return Metrics.this_week;
  return t as KlangTimePeriod;
}

function _metricFrom(sub_type: string): string {
  switch (sub_type) {
    case Search.sub_type_downloads:
      return Metrics.downloads;

    case Search.sub_type_best:
    default:
      return Metrics.best;
  }
}

function _collectionFrom(type: string): string {
  switch (type) {
    case Search.type_user:
      return Coll.users;

    // case Search.type_list:
    //   return Coll.lists;

    case Search.type_sound:
      return Coll.sounds;

    default:
      throw new UnsupportedQueryError();
  }
}

function _fieldMaskFrom(type: string): string[] {
  switch (type) {
    case Search.type_user:
      return FieldMasks.public_user_search;

    // case Search.type_list:
    //   return Coll.lists;

    case Search.type_sound:
    default:
      return FieldMasks.public_sound_search;
  }
}
