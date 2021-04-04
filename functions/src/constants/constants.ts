export class Root {
  static readonly info = "i";
  static readonly properties = "p";
  static readonly metrics = "m";
  static readonly legal = "f";
}

export class Info {
  static readonly id: string = "id";
  static readonly item_name: string = "nm";
  static readonly search_keys = "sk";
  static readonly tags = "tg";
  static readonly description = "dt";
  static readonly source_url = "rl";
  static readonly creator_id = "cd";
  static readonly timestamp_created = "tc";
  static readonly timestamp_updated = "tu";
  static readonly storage = "st";
  static readonly audio_file_bucket = "ab";
  static readonly audio_file_path = "ap";
  static readonly image_file_bucket = "ib";
  static readonly image_file_path = "ip";
}

export class Properties {
  static readonly explicit = "xp";
  static readonly hidden = "hn";
  static readonly search_keys = "sk";
  static readonly random_seeds = "rs";
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
}

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
}

export class ErrorCodes {
  static readonly invalid_username = "iu";
  static readonly invalid_email = "ie";
  static readonly emails_dont_match = "ed";
  static readonly invalid_uid = "id";
  static readonly invalid_pswd = "ip";
  static readonly pswds_dont_match = "pd";
  static readonly mission_failed = "mf";
}

export class Coll {
  static readonly sounds = "s";
  static readonly users = "u";
  static readonly lists = "l";
  static readonly usernames = "n";
}
