/**
 * character groups
 */
const c_g = {
  alphanumeric: "[a-zA-Z0-9]",

  // /** includes these: {@link https://unicode.org/charts/PDF/U0000.pdf} */
  // symbols: "[\u0021-\u002F\u003A-\u0040\u005B-\u0060\u007B-\u007E]",

  /** includes these: {@link https://unicode.org/charts/PDF/U0300.pdf                         (Combining Diacritical Marks)} */
  combining_diacritical_marks: "[\u0300-\u036F]",
  /** includes these: {@link https://unicode.org/charts/PDF/U1AB0.pdf                         (Combining Diacritical Marks Extended)} */
  combining_diacritical_marks_ext: "[\u1AB0-\u1AC0]",
  /** includes these: {@link https://unicode.org/charts/PDF/U1DC0.pdf   (from 1DC0-1DF9)      (Combining Diacritical Marks Supplement)} */
  combining_diacritical_marks_supp_1: "[\u1DC0-\u1DF9]",
  /** includes these: {@link https://unicode.org/charts/PDF/U1DC0.pdf   (from 1DFB-1DFF)      (...)} */
  combining_diacritical_marks_supp_2: "[\u1DFB-\u1DFF]",
  /** includes these: {@link https://unicode.org/charts/PDF/U20D0.pdf                         (Combining Diacritical Marks for Symbols)} */
  combining_diacritical_marks_for_symbols: "[\u20D0-\u20F0]",
  /** includes these: {@link https://unicode.org/charts/PDF/U1F300.pdf                        (Combining Half Marks)} */
  combining_half_marks: "[\uFE20-\uFE2F]",

  /** includes these: {@link https://unicode.org/charts/PDF/U1F600.pdf                        (Emoticons)} */
  emoticons: "[\ud83d[\ude00-\ude4f]",

  /** includes these: {@link https://unicode.org/charts/PDF/U2600.pdf                         (Miscellaneous Symbols)} */
  misc_symbols: "[\u2600-\u26ff]",

  /** includes these: {@link https://unicode.org/charts/PDF/U1F300.pdf  (from 1F300-1F3FF)    (Miscellaneous Symbols and Pictographs)} */
  misc_symbols_and_pictographs_1: "\ud83c[\udf00-\udfff]",
  /** includes these: {@link https://unicode.org/charts/PDF/U1F300.pdf  (from 1F400-1F5FF)    (...)} */
  misc_symbols_and_pictographs_2: "\ud83d[\udc00-\uddff]",

  /** includes these: {@link https://unicode.org/charts/PDF/U1F900.pdf  (from 1F900-1F978)    (Supplemental Symbols and Pictographs)} */
  supp_symbols_and_pictographs_1: "\ud83e[\udd00-\udd78]",
  /** includes these: {@link https://unicode.org/charts/PDF/U1F900.pdf  (from 1F97A-1F9CB)    (...)} */
  supp_symbols_and_pictographs_2: "\ud83e[\udd7a-\uddcb]",
  /** includes these: {@link https://unicode.org/charts/PDF/U1F900.pdf  (from 1F9CD-1F9FF)    (...)} */
  supp_symbols_and_pictographs_3: "\ud83e[\uddcd-\uddff]",

  /** includes these: {@link https://unicode.org/charts/PDF/U1FA70.pdf  (from 1FA70-1FA74)    (Symbols and Pictographs Extended-A)} */
  symbols_and_pictographs_ext_A_1: "\ud83e[\ude70-\ude74]",
  /** includes these: {@link https://unicode.org/charts/PDF/U1FA70.pdf  (from 1FA78-1FA7A)    (...)} */
  symbols_and_pictographs_ext_A_2: "\ud83e[\ude78-\ude7a]",
  /** includes these: {@link https://unicode.org/charts/PDF/U1FA70.pdf  (from 1FA80-1FA86)    (...)} */
  symbols_and_pictographs_ext_A_3: "\ud83e[\ude80-\ude86]",
  /** includes these: {@link https://unicode.org/charts/PDF/U1FA70.pdf  (from 1FA90-1FAA8)    (...)} */
  symbols_and_pictographs_ext_A_4: "\ud83e[\ude90-\udea8]",
  /** includes these: {@link https://unicode.org/charts/PDF/U1FA70.pdf  (from 1FAB0-1FAB6)    (...)} */
  symbols_and_pictographs_ext_A_5: "\ud83e[\udeb0-\udeb6]",
  /** includes these: {@link https://unicode.org/charts/PDF/U1FA70.pdf  (from 1FAC0-1FAC2)    (...)} */
  symbols_and_pictographs_ext_A_6: "\ud83e[\udec0-\udec2]",
  /** includes these: {@link https://unicode.org/charts/PDF/U1FA70.pdf  (from 1FAD0-1FAD6)    (...)} */
  symbols_and_pictographs_ext_A_7: "\ud83e[\uded0-\uded6]",

  /** includes these: {@link https://unicode.org/charts/PDF/U1F680.pdf  (from 1F680-1F6D7)    (Transport and Map Symbols)} */
  transport_and_map_symbols_1: "\ud83d[\ude80-\uded7]",
  /** includes these: {@link https://unicode.org/charts/PDF/U1F680.pdf  (from 1F6E0-1F6EC)    (...)} */
  transport_and_map_symbols_2: "\ud83d[\udee0-\udeec]",
  /** includes these: {@link https://unicode.org/charts/PDF/U1F680.pdf  (from 1F6F0-1F6FC)    (...)} */
  transport_and_map_symbols_3: "\ud83d[\udef0-\udefc]",

  /**
   * excerpts
   */

  /** some of these:    {@link https://unicode.org/charts/PDF/U1F300.pdf  (from 1F3FB-1F3FF)    (Miscellaneous Symbols and Pictographs)} */
  skin_colors: "\ud83c[\udffb-\udfff]",
  /** sincludes these:  {@link https://unicode.org/charts/PDF/UFE00.pdf                         (Variation Selectors)} */
  variation_selectors: "[\uFE00-\uFE0F]", // TODO: include supplement: https://unicode.org/charts/PDF/UE0100.pdf
  /** 1 from here:      {@link https://unicode.org/charts/PDF/U2000.pdf   (only 200D)           (General Punctuation)} */
  zwj: "[\u200d]",
};

// /**
//  * combined emojis
//  */
// const c_e = {
//   family: "👨‍👨‍👧‍👦|...",
// };

/**
 * strings for use with RegExp constructor
 */
export const reg_strings = {
  // allowed characters for ringtone & list names, with length limits too
  ringtone_and_list_name_indexed_chars:
    `${c_g.alphanumeric}|${c_g.emoticons}|${c_g.misc_symbols}|${c_g.misc_symbols_and_pictographs_1}|${c_g.misc_symbols_and_pictographs_2}|` +
    `${c_g.supp_symbols_and_pictographs_1}|${c_g.supp_symbols_and_pictographs_2}|${c_g.supp_symbols_and_pictographs_3}|` +
    `${c_g.symbols_and_pictographs_ext_A_1}|${c_g.symbols_and_pictographs_ext_A_2}|${c_g.symbols_and_pictographs_ext_A_3}|` +
    `${c_g.symbols_and_pictographs_ext_A_4}|${c_g.symbols_and_pictographs_ext_A_5}|${c_g.symbols_and_pictographs_ext_A_6}|` +
    `${c_g.symbols_and_pictographs_ext_A_7}|${c_g.transport_and_map_symbols_1}|${c_g.transport_and_map_symbols_2}|` +
    `${c_g.transport_and_map_symbols_3}`,

  allowed_ringtone_and_list_name:
    `^(${c_g.alphanumeric}|${c_g.emoticons}|${c_g.misc_symbols}|${c_g.misc_symbols_and_pictographs_1}|${c_g.misc_symbols_and_pictographs_2}|` +
    `${c_g.supp_symbols_and_pictographs_1}|${c_g.supp_symbols_and_pictographs_2}|${c_g.supp_symbols_and_pictographs_3}|` +
    `${c_g.symbols_and_pictographs_ext_A_1}|${c_g.symbols_and_pictographs_ext_A_2}|${c_g.symbols_and_pictographs_ext_A_3}|` +
    `${c_g.symbols_and_pictographs_ext_A_4}|${c_g.symbols_and_pictographs_ext_A_5}|${c_g.symbols_and_pictographs_ext_A_6}|` +
    `${c_g.symbols_and_pictographs_ext_A_7}|${c_g.transport_and_map_symbols_1}|${c_g.transport_and_map_symbols_2}|` +
    `${c_g.transport_and_map_symbols_3}){1,37}$`,

  all_diacritics:
    `${c_g.combining_diacritical_marks}|${c_g.combining_diacritical_marks_ext}|${c_g.combining_diacritical_marks_supp_1}|` +
    `${c_g.combining_diacritical_marks_supp_2}|${c_g.combining_diacritical_marks_for_symbols}|${c_g.combining_half_marks}`,

  skin_colors: c_g.skin_colors,
  variation_selectors: c_g.variation_selectors,
  zwj: c_g.zwj,
};
