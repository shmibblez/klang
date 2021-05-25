// ignore_for_file: non_const Stringant_identifier_names

class Root {
  static const info = "i";
  static const properties = "p";
  static const metrics = "m";
  static const legal = "f";
}

class Info {
  static const id = "id";
  static const item_name = "nm";
  static const search_keys = "sk";
  static const tags = "tg";
  static const tag_keys = "tk";
  static const description = "dt";
  static const source_url = "rl";
  static const creator_id = "cd";
  static const timestamp_created = "tc";
  static const timestamp_updated = "tu";
  static const storage = "st";
  static const audio_file_bucket = "ab";
  static const audio_file_path = "ap";
  static const image_file_bucket = "ib";
  static const image_file_path = "ip";
}

class Properties {
  static const explicit = "xp";
  static const hidden = "hn";
  static const search_keys = "sk";
  static const random_seeds = "rs";
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
}

class ErrorCodes {
  static const invalid_username = "iu";
  static const invalid_email = "ie";
  static const emails_dont_match = "ed";
  static const invalid_uid = "id";
  static const invalid_pswd = "ip";
  static const invalid_sound_name = "is";
  static const mission_failed = "mf";
  static const internal = "internal";
  static const no_sound = "ns";
  static const unsupported_file_extension = "uf";
  static const file_too_big = "fb";
  static const uid_taken = "ut";
  static const email_taken = "et";
}

// collection names
class Coll {
  static const sounds = "s";
  static const users = "u";
  static const lists = "l";
  static const usernames = "n";
}

class StoragePaths {
  static const sound = "s";
  static const list = "l";
  static const user = "u";
  static const sound_file_name = "a";
  static const list_image_name = "i";
  static const user_image_name = "i";
}

class Lengths {
  static const min_description_length = 1;
  static const max_description_length = 420;
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
  static const max_sound_name_length = 27;
  // max file size is 2.5 MB
  static const max_sound_file_size_bytes = 2500000;
  static const max_sound_duration_millis = 30000;
  static const supported_sound_file_extensions = [
    ".mp3",
    ".aac",
    ".flac",
    ".m4a",
  ];
}
