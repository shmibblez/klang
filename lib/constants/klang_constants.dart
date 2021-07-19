// ignore_for_file: non_const Stringant_identifier_names

class Root {
  static const info = "i";
  static const properties = "p";
  static const metrics = "m";
  static const legal = "f";
  static const deleted = "d";
  static const clone = "c";
  static const items = "t";
  static const local_params =
      "lp"; // used for passing db data to client within returned doc data
}

class LocalParams {
  static const full_doc_ref = "fdr";
}

class Info {
  static const id = "id";
  static const item_name = "nm";
  static const search_keys = "sk";
  static const tags = "tg";
  static const tag_keys = "tk";
  static const tag_history = "th";
  static const description = "dt";
  static const source_url = "rl";
  static const creator_id = "cd";
  static const timestamp_created = "tc";
  static const timestamp_updated = "tu";
  static const timestamp_checked = "te";
  static const storage = "st";
  static const audio_file_bucket = "ab";
  static const audio_file_path = "ap";
  static const audio_file_duration = "ad";
  static const image_file_bucket = "ib";
  static const image_file_path = "ip";
}

class Deleted {
  static const timestamp_deleted = "tt";
}

class Properties {
  static const explicit = "xp";
  static const hidden = "hn";
  static const search_keys = "sk";
  static const random_seeds = "rs";
  static const not_explicit_and_not_hidden = 0;
  static const explicit_and_not_hidden = 1;
  static const not_explicit_and_hidden = 2;
  static const explicit_and_hidden = 3;
}

class Metrics {
  static const timestamp_soonest_stale = "tss";
  static const downloads = "dn";
  static const saves = "sv";
  static const best = "bs";
  static const parent_lists = "pl";
  static const followers = "fs";
  static const following = "fw";
  static const sounds_created = "sc";
  static const lists_created = "lc";
  static const total = "tl";
  static const this_day = "td";
  static const this_week = "tw";
  static const this_month = "tm";
  static const this_year = "ty";
  static const this_decade = "tD";
  static const this_century = "tC";
  static const this_millenium = "tM";
  static const week_stale = "ws";
  static const month_stale = "ms";
  static const year_stale = "ys";
  static const decade_stale = "Ds";
  static const century_stale = "Cs";
  static const millenium_stale = "Ms";
}

const KlangTimePeriods = [
  Metrics.total,
  Metrics.this_day,
  Metrics.this_week,
  Metrics.this_month,
  Metrics.this_year,
  Metrics.this_decade,
  Metrics.this_century,
  Metrics.this_millenium
];

class Legal {
  static const received_copyright_notices = "rcn";
  static const received_trademark_notices = "rtn";
  static const times_audio_file_reported = "tar";
  static const times_image_file_reported = "tir";
  static const times_text_reported = "ttr";
}

class DuplicateChild {
  static const ids = "ids";
}

class Following {
  static const following = "fw";
  static const follower = "fr";
  static const timestamp_followed = "tf";
}

class Username {
  static const username = "n";
  static const uid = "d";
}

class Clone {
  static const ids = "z";
  static const available_clone_ids = "ai";
  static const space_available = "sa";
  static const clone_count = "dc";
}

class RTDB {
  static const username = "n";
  static const metrics = "m";
  static const users = "u";
  static const lists = "l";
}

class FunctionParams {
  static const email = "e";
  static const email_confirmation = "ec";
  static const password = "p";
  static const password_confirmation = "pc";
  static const sound_file_bytes = "sb";
  static const sound_file_name = "sn";
  static const timestamp = "t";
  static const timestamp_seconds = "_seconds";
  static const timestamp_nanoseconds = "_nanoseconds";
  static const force_query = "fq";
  static const force_sound_query = "fsq";
  static const force_list_query = "flq";
}

class FunctionResult {
  static const items = "i";
  static const sounds = "s";
  static const lists = "l";
}

class Search {
  static const type = "t";
  static const type_user = "u";
  static const type_sound = "s";
  static const type_list = "l";
  static const direction_asc = "asc";
  static const direction_desc = "desc";
  static const sub_type = "y";
  static const sub_type_random = "r";
  static const sub_type_sk = "k";
  static const sub_type_downloads = Metrics.downloads;
  static const sub_type_best = Metrics.best;
  static const sub_type_item = "i";
  static const random_seed_num = "n";
  static const direction = "e";
  static const offset = "o";
  static const time_period = "m";
}

class GetSavedItems {
  static const ids = "ds";
  static const type = "ty";
  static const type_saved_items_doc = "d";
  static const type_saved_items_sort = "c"; // c for clones
  static const type_saved_items_timestamp_saved = "tm";
  static const metric = "m";
  static const content_type = "ct";
}

class ErrorCodes {
  static const invalid_username = "iu";
  static const invalid_email = "ie";
  static const invalid_uid = "id";
  static const invalid_pswd = "ip";
  static const invalid_sound_name = "is";
  static const invalid_doc_id = "ii";
  static const mission_failed = "mf";
  static const unauthenticated = "ua";
  static const internal = "internal";
  static const no_sound = "ns";
  static const sound_duration_too_long = "sl";
  static const file_too_big = "fb";
  static const unsupported_file_extension = "uf";
  static const uid_taken = "ut";
  static const email_taken = "et";
  static const unsupported_query = "uq";
  static const nonexistent_doc = "nd";
  static const already_saved = "av";
  static const not_saved = "nv";
  static const limit_overflow = "lo";
}
// collection names

// - root-level collections are denoted by 1 character

// - sub-collections are denoted by 2 characters
class Coll {
  static const sounds = "s";
  static const users = "u";
  static const lists = "l";
  static const usernames = "n";
  static const saves = "sv";
  static const user_saved = "sd";
}

class Docs {
  static const saved_sounds = "ss";
  static const saved_lists = "sl";
}

class StoragePaths {
  static const sounds = "s";
  static const lists = "l";
  static const users = "u";
  static const sound_file_name = "a";
  static const list_image_name = "i";
  static const user_image_name = "i";
}

class Lengths {
  static const min_description_length = 0;
  static const max_description_length = 720;
  static const min_username_length = 4;
  static const max_username_length = 17;
  static const min_uid_length = 7;
  static const max_uid_length = 21;
  static const min_tag_length = 3;
  static const max_tag_length = 17;
  static const max_sound_tags = 3;
  static const min_pswd_length = 5;
  static const max_pswd_length = 100;
  static const min_sound_name_length = 3;
  static const max_sound_name_length = 47;
  static const max_saved_sounds = 100;
  // max file size is 2.5 MB
  static const max_sound_file_size_bytes = 2500000;
  static const max_sound_duration_millis = 30000;
  static const supported_sound_file_extensions = [
    ".mp3",
    ".aac",
    ".flac",
    ".m4a"
  ];
  static const max_clone_sound_uids = 1000;
}

class Misc {
  static const storage_bucket = "klang-7.appspot.com";
  static const storage_sound_file_ext = ".aac";
  static const storage_sound_file_mime = "aac";
  static const wildcard_str = "?";
}

class FieldMasks {
  // for sound list item
  static const public_sound_search = [
    '''${Root.info}.${Info.id}''',
    '''${Root.info}.${Info.item_name}.${Info.item_name}''',
    '''${Root.info}.${Info.tags}''',
    '''${Root.info}.${Info.description}''',
    '''${Root.info}.${Info.source_url}''',
    '''${Root.info}.${Info.creator_id}''',
    '''${Root.info}.${Info.timestamp_created}''',
    '''${Root.info}.${Info.timestamp_updated}''',
    '''${Root.info}.${Info.storage}''',
    // `${Root.info}.${Info.storage}.${Info.audio_file_bucket}`,

    // `${Root.info}.${Info.storage}.${Info.audio_file_path}`,
    '''${Root.properties}.${Properties.explicit}''',
    '''${Root.metrics}.${Metrics.downloads}''',
    '''${Root.metrics}.${Metrics.best}''',
    '''${Root.metrics}.${Metrics.saves}'''
  ];
  // for user list item
  static const public_user_search = [
    // TODO: what else?
    '''${Root.info}.${Info.item_name}.${Info.item_name}''',
    '''${Root.info}.${Info.tags}''',
    '''${Root.info}.${Info.tag_history}''',
    '''${Root.info}.${Info.description}''',
    '''${Root.info}.${Info.timestamp_created}''',
    '''${Root.info}.${Info.timestamp_updated}''',
    '''${Root.info}.${Info.storage}''',
    // `${Root.info}.${Info.storage}.${Info.audio_file_bucket}`,

    // `${Root.info}.${Info.storage}.${Info.audio_file_path}`,
    '''${Root.deleted}.${Deleted.timestamp_deleted}''',
    '''${Root.properties}.${Properties.explicit}''',
    '''${Root.metrics}.${Metrics.followers}''',
    '''${Root.metrics}.${Metrics.following}'''
  ];
}

class Dates {
  static const reference_year = 2000;
  // static const reference_date = new Date(2000, 0);
  static const offset_for_day_in_hours = 6;
  static const offset_for_week_in_days = 3;
  static const offset_for_month_in_days = 7;
  static const offset_for_year_in_days = 30;
  static const offset_for_decade_in_years = 1;
  static const offset_for_century_in_years = 10;
  static const offset_for_millenium_in_years = 100;
}
