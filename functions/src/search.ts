import { firestore } from "firebase-admin";
import { https } from "firebase-functions";
import Graphemer from "graphemer";
import {
  Properties,
  Search,
  Info,
  Coll,
  Root,
  Lengths,
  Misc,
  KlangTimePeriod,
  KlangTimePeriods,
  Metrics,
  FieldMasks,
  FunctionResult,
} from "./constants/constants";
import { InvalidDocIdError, UnsupportedQueryError } from "./constants/errors";
import { reg_strings } from "./constants/regex";
import { isDocIdOk, isTagOk } from "./field_checks";

export const search = https.onCall(async (data, context) => {
  const search_type = data[Search.type];
  const limit = 20;
  const coll = _collectionFrom(search_type);
  const fieldMask = _fieldMaskFrom(search_type);

  let query: firestore.Query;

  // since all doc types have same doc structure, can reuse types. Still need to check if type - sub-type pair is valid, since users can't have downloads for example
  query = _itemSearch({ data: data, coll: coll, fieldMask: fieldMask });
  query = query.limit(limit);

  const snap = await query.get();
  console.log(`search: result size: ${snap.docs.length}`);
  return {
    [FunctionResult.items]: snap.docs.map<firestore.DocumentData>((doc) =>
      doc.data()
    ),
  };
});

function _itemSearch({
  data,
  coll,
  fieldMask,
}: {
  data: any;
  coll: string;
  fieldMask: string[];
}): firestore.Query {
  const explicit_ok = data[Properties.explicit] == true ? true : false;
  const explicit_property = [
    explicit_ok
      ? Properties.explicit_and_not_hidden
      : Properties.not_explicit_and_not_hidden,
  ];
  if (explicit_ok)
    explicit_property.push(Properties.not_explicit_and_not_hidden);
  const tags_sk = _tagsSearchKey(data[Info.tags]);
  tags_sk;
  const sub_type = data[Search.sub_type];
  const offset = data[Search.offset];

  console.log("search: offset: " + offset);

  let query: firestore.Query = firestore().collection(coll);

  /// set explicit filters (supported by all queries)
  query = query.where(
    `${Root.properties}.${Properties.search_keys}`,
    "in",
    explicit_property
  );

  /// queries that don't support tag filters, need to set field mask and return
  switch (sub_type) {
    case Search.sub_type_item:
      let item_id = data[Info.id];
      console.log("search: item_id: " + item_id);
      if (!isDocIdOk(item_id)) throw new InvalidDocIdError();
      query = query.where(firestore.FieldPath.documentId(), "==", item_id);
      query = query.select(...fieldMask);
      return query;
  }

  /// set tag filters for queries that support them
  query = query.where(
    `${Root.info}.${Info.tag_keys}`,
    "array-contains",
    tags_sk !== undefined ? tags_sk : Misc.wildcard_str
  );

  switch (sub_type) {
    case Search.sub_type_downloads:
    case Search.sub_type_best:
      const time_period = _timePeriodFrom(data[Search.time_period]);
      const metric = _metricFrom(sub_type);
      /**
       *  explicit & tag filters already set
       **/
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
        if (k) {
          console.log(
            `search: adding filter for key "${k}", path: "${Root.info}.${Info.item_name}.${Info.search_keys}.${k}"`
          );
          query = query.where(
            `${Root.info}.${Info.item_name}.${Info.search_keys}.${k}`,
            "==",
            true
          );
        } else console.log("search: invalid search key length: " + k.length);
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

  const keys: { [k: string]: true } = {};
  const splitter = new Graphemer();

  // split string into words ex: "abc def" -> ["abc", "def"]
  const words = name
    .normalize("NFKD") //                                           splits diacritics from letters
    .replace(RegExp(reg_strings.all_diacritics, "g"), "") //        remove diacritics
    .replace(RegExp(reg_strings.skin_colors, "g"), "") //           remove emoji skin colors
    .replace(RegExp(reg_strings.variation_selectors, "g"), "") //   remove variation selectors
    /** no need to remove hair colors since, when their ZWJ is removed, ther're considered separate emojis */
    .normalize("NFKC") //                                           re-combines everything (shouldn't really do anything at this point but just to be safe)
    .trim() //                                                      remove leading and trailing spaces
    .replace(/\s+/g, " ")
    .split(" ");
  for (const w of words) {
    // split into graphemes and index each one
    const graphemes = splitter.splitGraphemes(w);
    for (let i = 0; i < graphemes.length - 1; i++) {
      keys[graphemes[i] + graphemes[i + 1]] = true;
    }
  }

  return Object.keys(keys);
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
  if (!KlangTimePeriods.includes(t as KlangTimePeriod))
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
