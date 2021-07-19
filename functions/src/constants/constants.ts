import {
  addDays,
  addMonths,
  addWeeks,
  addYears,
  differenceInDays,
  differenceInHours,
  differenceInYears,
  endOfDay,
  lastDayOfDecade,
  lastDayOfMonth,
  lastDayOfWeek,
  lastDayOfYear,
} from "date-fns";

export class Root {
  static readonly info = "i";
  static readonly properties = "p";
  static readonly metrics = "m";
  static readonly legal = "f";
  static readonly deleted = "d";
  static readonly clone = "c";
  static readonly items = "t";
  static readonly local_params = "lp"; // used for passing db data to client within returned doc data
}

export class LocalParams {
  static readonly full_doc_ref = "fdr";
}

export class Info {
  static readonly id = "id";
  static readonly item_name = "nm";
  static readonly search_keys = "sk";
  static readonly tags = "tg";
  static readonly tag_keys = "tk";
  static readonly tag_history = "th";
  static readonly description = "dt";
  static readonly source_url = "rl";
  static readonly creator_id = "cd";
  static readonly timestamp_created = "tc";
  static readonly timestamp_updated = "tu";
  static readonly timestamp_checked = "te";
  static readonly storage = "st";
  static readonly audio_file_bucket = "ab";
  static readonly audio_file_path = "ap";
  static readonly audio_file_duration = "ad";
  static readonly image_file_bucket = "ib";
  static readonly image_file_path = "ip";
}

export class Deleted {
  static readonly timestamp_deleted = "tt";
}

export class Properties {
  static readonly explicit = "xp";
  static readonly hidden = "hn";
  static readonly search_keys = "sk";
  static readonly random_seeds = "rs";
  static readonly not_explicit_and_not_hidden = 0;
  static readonly explicit_and_not_hidden = 1;
  static readonly not_explicit_and_hidden = 2;
  static readonly explicit_and_hidden = 3;
}

export class Metrics {
  static readonly timestamp_soonest_stale = "tss";
  static readonly downloads = "dn";
  static readonly saves = "sv";
  static readonly best = "bs";
  static readonly parent_lists = "pl";
  static readonly followers = "fs";
  static readonly following = "fw";
  static readonly sounds_created = "sc";
  static readonly lists_created = "lc";
  static readonly total = "tl";
  static readonly this_day = "td";
  static readonly this_week = "tw";
  static readonly this_month = "tm";
  static readonly this_year = "ty";
  static readonly this_decade = "tD";
  static readonly this_century = "tC";
  static readonly this_millenium = "tM";
  static readonly week_stale = "ws";
  static readonly month_stale = "ms";
  static readonly year_stale = "ys";
  static readonly decade_stale = "Ds";
  static readonly century_stale = "Cs";
  static readonly millenium_stale = "Ms";

  static matchToTimePeriodStale(tp: KlangTimePeriod): string {
    if (!KlangTimePeriods.includes(tp))
      throw `time period not in KlangTimePeriods: ${tp}`;
    if (tp === Metrics.total || tp === Metrics.this_day) {
      return tp;
    }
    switch (tp) {
      case Metrics.this_week:
        return Metrics.week_stale;
      case Metrics.this_month:
        return Metrics.month_stale;
      case Metrics.this_year:
        return Metrics.year_stale;
      case Metrics.this_decade:
        return Metrics.decade_stale;
      case Metrics.this_century:
        return Metrics.century_stale;
      case Metrics.this_millenium:
        return Metrics.millenium_stale;
    }
  }
}
export type KlangMetric = "dn" | "sv" | "bs" | "pl" | "fs" | "fw" | "sc" | "lc";
export type KlangTimePeriod =
  | "tl"
  | "td"
  | "tw"
  | "tm"
  | "ty"
  | "tD"
  | "tC"
  | "tM";
export const KlangTimePeriods: KlangTimePeriod[] = [
  Metrics.total,
  Metrics.this_day,
  Metrics.this_week,
  Metrics.this_month,
  Metrics.this_year,
  Metrics.this_decade,
  Metrics.this_century,
  Metrics.this_millenium,
];

export class Legal {
  static readonly received_copyright_notices = "rcn";
  static readonly received_trademark_notices = "rtn";
  static readonly times_audio_file_reported = "tar";
  static readonly times_image_file_reported = "tir";
  static readonly times_text_reported = "ttr";
}

export class DuplicateChild {
  static readonly ids = "ids";
}

export class Following {
  static readonly following = "fw";
  static readonly follower = "fr";
  static readonly timestamp_followed = "tf";
}

export class Username {
  static readonly username = "n";
  static readonly uid = "d";
}

export class Clone {
  static readonly ids = "z";
  // static readonly available_clone_ids = "ai"; // not necessary
  static readonly space_available = "sa";
  static readonly clone_count = "dc";
}

export class RTDB {
  static readonly username = "n";
  static readonly metrics = "m";
  static readonly users = "u";
  static readonly lists = "l";
}

export class FunctionParams {
  static readonly email = "e";
  static readonly email_confirmation = "ec";
  static readonly password = "p";
  static readonly password_confirmation = "pc";
  static readonly sound_file_bytes = "sb";
  static readonly sound_file_name = "sn";
  static readonly timestamp = "t";
  static readonly timestamp_seconds = "_seconds";
  static readonly timestamp_nanoseconds = "_nanoseconds";
  static readonly force_query = "fq";
  static readonly force_sound_query = "fsq";
  static readonly force_list_query = "flq";
}

export class FunctionResult {
  static readonly items = "i";
  static readonly sounds = "s";
  static readonly lists = "l";
}

export class Search {
  static readonly type = "t";
  static readonly type_user = "u";
  static readonly type_sound = "s";
  static readonly type_list = "l";
  static readonly direction_asc = "asc";
  static readonly direction_desc = "desc";
  static readonly sub_type = "y";
  static readonly sub_type_random = "r";
  static readonly sub_type_sk = "k";
  static readonly sub_type_downloads = Metrics.downloads;
  static readonly sub_type_best = Metrics.best;
  static readonly sub_type_item = "i";
  static readonly random_seed_num = "n";
  static readonly direction = "e";
  static readonly offset = "o";
  static readonly time_period = "m";
}

export class GetSavedItems {
  static readonly ids = "ds";
  static readonly type = "ty";
  static readonly type_saved_items_doc = "d";
  static readonly type_saved_items_sort = "c"; // c for clones
  static readonly type_saved_items_timestamp_saved = "tm";
  static readonly metric = "m";
  static readonly content_type = "ct";
  static readonly supported_metrics = [
    Metrics.downloads,
    Metrics.saves,
    Metrics.best,
  ];
}

export class ErrorCodes {
  static readonly invalid_username = "iu";
  static readonly invalid_email = "ie";
  static readonly invalid_uid = "id";
  static readonly invalid_pswd = "ip";
  static readonly invalid_sound_name = "is";
  static readonly invalid_doc_id = "ii";
  static readonly mission_failed = "mf";
  static readonly unauthenticated = "ua";
  static readonly internal = "internal";
  static readonly no_sound = "ns";
  static readonly sound_duration_too_long = "sl";
  static readonly file_too_big = "fb";
  static readonly unsupported_file_extension = "uf";
  static readonly uid_taken = "ut";
  static readonly email_taken = "et";
  static readonly unsupported_query = "uq";
  static readonly nonexistent_doc = "nd";
  static readonly already_saved = "av";
  static readonly not_saved = "nv";
  static readonly limit_overflow = "lo";
}

// collection names
// - root-level collections are denoted by 1 character
// - sub-collections are denoted by 2 characters
export class Coll {
  static readonly sounds = "s";
  static readonly users = "u";
  static readonly lists = "l";
  static readonly usernames = "n";
  static readonly saves = "sv";
  static readonly user_saved = "sd";
}

export class Docs {
  static readonly saved_sounds = "ss";
  static readonly saved_lists = "sl";
}

export class StoragePaths {
  static readonly sounds = "s";
  static readonly lists = "l";
  static readonly users = "u";
  static readonly sound_file_name = "a";
  static readonly list_image_name = "i";
  static readonly user_image_name = "i";
}

export class Lengths {
  static readonly min_description_length = 0;
  static readonly max_description_length = 720;
  static readonly min_username_length = 4;
  static readonly max_username_length = 17;
  static readonly min_uid_length = 7;
  static readonly max_uid_length = 21;
  static readonly min_tag_length = 3;
  static readonly max_tag_length = 17;
  static readonly max_sound_tags = 3;
  static readonly min_pswd_length = 5;
  static readonly max_pswd_length = 100;
  static readonly min_sound_name_length = 3;
  static readonly max_sound_name_length = 47;
  static readonly max_saved_sounds = 100;
  // max file size is 2.5 MB
  static readonly max_sound_file_size_bytes = 2500000;
  static readonly max_sound_duration_millis = 30000;
  static readonly supported_sound_file_extensions = [
    ".mp3",
    ".aac",
    ".flac",
    ".m4a",
  ];
  static readonly max_clone_sound_uids = 1000;
}

export class Misc {
  static readonly storage_bucket = "klang-7.appspot.com";
  static readonly storage_sound_file_ext = ".aac";
  static readonly storage_sound_file_mime = "aac";
  static readonly wildcard_str = "?";
}

export class FieldMasks {
  // for sound list item
  static readonly public_sound_search = [
    `${Root.info}.${Info.id}`,
    `${Root.info}.${Info.item_name}.${Info.item_name}`,
    `${Root.info}.${Info.tags}`,
    `${Root.info}.${Info.description}`,
    `${Root.info}.${Info.source_url}`,
    `${Root.info}.${Info.creator_id}`,
    `${Root.info}.${Info.timestamp_created}`,
    `${Root.info}.${Info.timestamp_updated}`,
    `${Root.info}.${Info.storage}`,
    // `${Root.info}.${Info.storage}.${Info.audio_file_bucket}`,
    // `${Root.info}.${Info.storage}.${Info.audio_file_path}`,
    `${Root.properties}.${Properties.explicit}`,
    `${Root.metrics}.${Metrics.downloads}`,
    `${Root.metrics}.${Metrics.best}`,
    `${Root.metrics}.${Metrics.saves}`,
  ];
  // for user list item
  static readonly public_user_search = [
    // TODO: what else?
    `${Root.info}.${Info.item_name}.${Info.item_name}`,
    `${Root.info}.${Info.tags}`,
    `${Root.info}.${Info.tag_history}`,
    `${Root.info}.${Info.description}`,
    `${Root.info}.${Info.timestamp_created}`,
    `${Root.info}.${Info.timestamp_updated}`,
    `${Root.info}.${Info.storage}`,
    // `${Root.info}.${Info.storage}.${Info.audio_file_bucket}`,
    // `${Root.info}.${Info.storage}.${Info.audio_file_path}`,
    `${Root.deleted}.${Deleted.timestamp_deleted}`,
    `${Root.properties}.${Properties.explicit}`,
    `${Root.metrics}.${Metrics.followers}`,
    `${Root.metrics}.${Metrics.following}`,
  ];
}

export class Dates {
  static readonly reference_year = 2000;
  static readonly reference_date = new Date(2000, 0);
  static readonly offset_for_day_in_hours = 6;
  static readonly offset_for_week_in_days = 3;
  static readonly offset_for_month_in_days = 7;
  static readonly offset_for_year_in_days = 30;
  static readonly offset_for_decade_in_years = 1;
  static readonly offset_for_century_in_years = 10;
  static readonly offset_for_millenium_in_years = 100;

  static currentTimePeriodEnd({ tp }: { tp: KlangTimePeriod }): Date {
    const now = new Date();
    if (tp === Metrics.total || tp === Metrics.this_day) return new Date(0, 0);
    switch (tp) {
      case Metrics.this_week:
        return lastDayOfWeek(now);
      case Metrics.this_month:
        return lastDayOfMonth(now);
      case Metrics.this_year:
        return lastDayOfYear(now);
      case Metrics.this_decade:
        return lastDayOfDecade(now);
      case Metrics.this_century: {
        const years = differenceInYears(now, Dates.reference_date);
        let centuries = Math.ceil(years / 100);
        const future = addYears(Dates.reference_date, centuries * 100);
        // if within first year of century since `differenceinYears()` returns int
        if (now >= future) return addYears(future, 100);
        return future;
      }
      case Metrics.this_millenium: {
        const years = differenceInYears(now, Dates.reference_date);
        const milleniums = Math.ceil(years / 1000);
        const future = addYears(Dates.reference_date, milleniums * 1000);
        // if within first year of millenium `differenceinYears()` returns int
        if (now >= future) return addYears(future, 1000);
        return future;
      }
    }
  }

  static nextTimePeriodEnd({ tp }: { tp: KlangTimePeriod }): Date {
    const now = new Date();
    if (tp === Metrics.total) return new Date(0, 0);
    switch (tp) {
      case Metrics.this_day:
        return endOfDay(addDays(now, 1));
      case Metrics.this_week:
        return lastDayOfWeek(addWeeks(now, 1));
      case Metrics.this_month:
        return lastDayOfMonth(addMonths(now, 1));
      case Metrics.this_year:
        return lastDayOfYear(addYears(now, 1));
      case Metrics.this_decade:
        return lastDayOfDecade(addYears(now, 10));
      case Metrics.this_century: {
        const years = differenceInYears(now, Dates.reference_date);
        let centuries = Math.ceil(years / 100);
        const future = addYears(Dates.reference_date, centuries * 100);
        // if within first year of century since `differenceinYears()` returns int
        if (now >= future) return addYears(future, 200);
        return addYears(future, 100);
      }
      case Metrics.this_millenium: {
        const years = differenceInYears(now, Dates.reference_date);
        const milleniums = Math.ceil(years / 1000);
        const future = addYears(Dates.reference_date, milleniums * 1000);
        // if within first year of millenium `differenceinYears()` returns int
        if (now >= future) return addYears(future, 2000);
        return addYears(future, 1000);
      }
    }
  }

  static withinOffsetPeriod({
    tp,
    date = new Date(),
  }: {
    tp: KlangTimePeriod;
    date?: Date;
  }): boolean {
    if (tp === Metrics.total) return false;
    const current_tp_end = this.currentTimePeriodEnd({ tp: tp });
    if (date == current_tp_end) return true;
    const dateLeft = date > current_tp_end ? date : current_tp_end;
    const dateRight = date > current_tp_end ? current_tp_end : date;
    switch (tp) {
      case Metrics.this_day:
        return (
          differenceInHours(dateLeft, dateRight) <=
          Dates.offset_for_day_in_hours
        );
      case Metrics.this_week:
        return (
          differenceInDays(dateLeft, dateRight) <= Dates.offset_for_week_in_days
        );
      case Metrics.this_month:
        return (
          differenceInDays(dateLeft, dateRight) <=
          Dates.offset_for_month_in_days
        );
      case Metrics.this_year:
        return (
          differenceInDays(dateLeft, dateRight) <= Dates.offset_for_year_in_days
        );
      case Metrics.this_decade:
        return (
          differenceInYears(dateLeft, dateRight) <=
          Dates.offset_for_decade_in_years
        );
      case Metrics.this_century: {
        return (
          differenceInDays(dateLeft, dateRight) <=
          Dates.offset_for_century_in_years
        );
      }
      case Metrics.this_millenium: {
        return (
          differenceInDays(dateLeft, dateRight) <=
          Dates.offset_for_millenium_in_years
        );
      }
    }
  }
}
