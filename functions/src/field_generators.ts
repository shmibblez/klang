import { randomBytes } from "crypto";
import Graphemer from "graphemer";
import { Lengths, Metrics, Misc, Properties } from "./constants/constants";
import { reg_strings } from "./constants/regex";
import { isTagOk } from "./field_checks";

/**
 *
 * @param s string to index
 * @returns {[string pair]: true} -> map of indexed string pairs
 *
 * used to index usernames and item names
 */
export function indexName(s: string) {
  const splitter = new Graphemer();
  const keys: { [k: string]: true } = {};

  /** {@link operation_baby_steps remove diacritics, skin color, and trailing & duplicate spaces} */
  // remove diacritics
  const clean = s
    .normalize("NFKD") //                                           splits diacritics from letters
    .replace(RegExp(reg_strings.all_diacritics, "g"), "") //        remove diacritics
    .replace(RegExp(reg_strings.skin_colors, "g"), "") //           remove emoji skin colors
    .replace(RegExp(reg_strings.variation_selectors, "g"), "") //   remove variation selectors
    /** no need to remove hair colors since, when their ZWJ is removed, ther're considered separate emojis */
    .normalize("NFKC") //                                           re-combines everything (shouldn't really do anything at this point but just to be safe)
    .trim() //                                                      remove leading and trailing spaces
    .replace(/\s+/g, " "); //                                       remove duplicate spaces

  //

  /** {@link phase1.0 index all graphemes individually} */
  const cleanGraphemes = splitter.splitGraphemes(clean);
  for (const letter of cleanGraphemes) {
    keys[letter] = true;
  }

  //

  /** {@link phase1.1 split composite emojis and index all graphemes individually} */
  const phase1_2 = clean.replace(RegExp(reg_strings.zwj, "g"), "");
  const splitCleanGraphemes = splitter.splitGraphemes(phase1_2); // remove zwj -> 👨‍👩‍👧‍👦 -> 👨👩👧👦
  for (const letter of splitCleanGraphemes) {
    keys[letter] = true;
  }
  delete keys[" "]; // remove space in case indexed in phase 1.0 or 1.1

  //

  /** {@link phase2.0 index string pairs, no filtering} */
  _indexGraphemes(clean);

  //

  /** {@link phase2.1 index string pairs with composite emojis split} */
  const phase2_1 = clean.replace(RegExp(reg_strings.zwj, "g"), "");
  _indexGraphemes(phase2_1);

  //

  /** {@link phase3 filter out anything that isn't /[A-Za-z0-9\s_-], and index string pairs} */
  const phase3 = clean
    .replace(/[^A-Za-z0-9\s_-]/g, "")
    .trim()
    .replace(/\s+/g, " ");
  _indexGraphemes(phase3);

  //

  /** {@link phase4:_the_last_enchilada filter out anything that isn't /[A-Za-z0-9\s], and index string pairs} */
  const phase4 = clean
    .replace(/[^A-Za-z0-9\s]/g, "")
    .trim()
    .replace(/\s+/g, " ");
  _indexGraphemes(phase4);

  // add wildcard string (matches nothing -> "")
  keys[Misc.wildcard_str] = true;

  return keys;

  // indexes graphemes in pairs
  function _indexGraphemes(str: string) {
    // split string into words ex: "abc def" -> ["abc", "def"]
    const words = str.split(" ");
    for (const w of words) {
      // split into graphemes and index each one
      const graphemes = splitter.splitGraphemes(w);
      for (let i = 0; i < graphemes.length - 1; i++) {
        keys[graphemes[i] + graphemes[i + 1]] = true;
      }
    }
  }
}

export function indexProperties(e: boolean, h: boolean) {
  if (!e && !h) {
    // not_explicit & not_hidden
    return Properties.not_explicit_and_not_hidden;
  } else if (e && !h) {
    // explicit & not_hidden
    return Properties.explicit_and_not_hidden;
  } else if (!e && h) {
    // not_explicit & hidden
    return Properties.not_explicit_and_hidden;
  } else if (e && h) {
    // explicit & hidden
    return Properties.explicit_and_hidden;
  } else {
    throw new Error("this should not happen");
  }
}

export function randomSeeds() {
  return { 1: randomNum(), 2: randomNum(), 3: randomNum(), 4: randomNum() };

  function randomNum() {
    let num: number;
    try {
      const buf = randomBytes(4);
      num = parseInt(buf.toString("hex"), 16);
    } catch (e) {
      num = Math.random() * 0xffffffff;
    }
    return Math.trunc(num);
  }
}

export function initMetric() {
  return {
    [Metrics.total]: 0,
    [Metrics.this_day]: 0,
    [Metrics.this_week]: 0,
    [Metrics.this_month]: 0,
    [Metrics.this_year]: 0,
    [Metrics.this_decade]: 0,
    [Metrics.this_century]: 0,
    [Metrics.this_millenium]: 0,
  };
}

export function tagsFromStr(t: string): string[] {
  if (t.length <= 0) return [];
  let tags = t.split(",");
  if (tags.length > Lengths.max_sound_tags)
    tags.length = Lengths.max_sound_tags;

  tags.forEach((tag, i, arr) => (arr[i] = tag.trim().replace(/\s{2,}/g, " ")));
  tags = tags.filter((tag) => isTagOk(tag));
  return tags;
}

// IMPORTANT: only 3 tags can be indexed, can keep it simple
export function indexTags(t: string[]) {
  let tags: string[] = [];
  for (const tag of t) {
    tags.push(tag);
  }
  if (tags.length > Lengths.max_sound_tags)
    tags.length = Lengths.max_sound_tags;
  tags = tags.sort((a, b) => a.localeCompare(b, "en-US"));

  // add wildcard tag str
  const indx: string[] = [Misc.wildcard_str];

  if (tags.length <= 0) return indx;
  if (tags.length >= 1) {
    indx.push(tags[0]);
  }
  if (tags.length >= 2) {
    indx.push(tags[1]);
    indx.push(tags[0] + "|" + tags[1]);
  }
  if (tags.length >= 3) {
    indx.push(tags[2]);
    indx.push(tags[0] + "|" + tags[2]);
    indx.push(tags[1] + "|" + tags[2]);
    indx.push(tags[0] + "|" + tags[1] + "|" + tags[2]);
  }
  return indx;
}

/**
 *
 * @param uid sound owner id
 * @param name sound name
 * @param randomize_end is called if id already taken, adds some extra random chars at the end
 * @returns string with the format [uid+name], where all characters for name that aren't in [A-Za-z-] are replaced with -, no uid characters are replaced
 */
export function generateSoundId({
  name,
  randomize_end = false,
}: {
  name: string;
  randomize_end?: boolean;
}): string {
  // don't need to worry about __.*__
  let clean_name = name
    .replace(/[^A-Za-z0-9-]/g, "-")
    .replace(/-{2,}/g, "-")
    .replace(/-$/, "")
    .replace(/^-/g, "");

  if (clean_name.length < 4) {
    clean_name += "-" + randomStr(4);
  } else if (randomize_end) {
    clean_name += "-" + randomStr(2);
  }
  return clean_name;
}

/**
 *
 * @param length length of random string to return
 * @returns random alphanumeric string of specified [length]
 */
export function randomStr(length: number): string {
  const chars =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  let str = "";
  while (str.length < 20) {
    const bytes = randomBytes(40);
    bytes.forEach((b) => {
      // Length of `chars` is 62. We only take bytes between 0 and 62*4-1
      // (both inclusive). The value is then evenly mapped to indices of `char`
      // via a modulo operation. If maxValue weren't set, then id could be
      // bias towards first 3 chars, or first (255 - maxValue) chars
      const maxValue = 62 * 4 - 1;
      if (str.length < 20 && b <= maxValue) {
        str += chars.charAt(b % 62);
      }
    });
  }
  return str;
}
