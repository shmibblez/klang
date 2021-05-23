// ignore_for_file: non_const Stringant_identifier_names

class Root {
  static const String info = "i";
  static const String properties = "p";
  static const String metrics = "m";
  static const String legal = "f";
}

class Info {
  static const String id = "id";
  static const String item_name = "nm";
  static const String search_keys = "sk";
  static const String tags = "tg";
  static const String tag_keys = "tk";
  static const String description = "dt";
  static const String source_url = "rl";
  static const String creator_id = "cd";
  static const String timestamp_created = "tc";
  static const String timestamp_updated = "tu";
  static const String storage = "st";
  static const String audio_file_bucket = "ab";
  static const String audio_file_path = "ap";
  static const String image_file_bucket = "ib";
  static const String image_file_path = "ip";
}

class Properties {
  static const String explicit = "xp";
  static const String hidden = "hn";
  static const String search_keys = "sk";
  static const String random_seeds = "rs";
}

class Metrics {
  static const String timestamp_soonest_stale = "tss";
  static const String downloads = "dn";
  static const String saves = "sv";
  static const String best = "bs";
  static const String parent_lists = "pl";
  static const String followers = "fs";
  static const String following = "fw";
  static const String sounds_created = "sc";
  static const String lists_created = "lc";
  static const String total = "tl";
  static const String this_day = "td";
  static const String this_week = "tw";
  static const String this_month = "tm";
  static const String this_year = "ty";
  static const String this_decade = "tD";
  static const String this_century = "tC";
  static const String this_millenium = "tM";
  static const String week_stale = "ws";
  static const String month_stale = "ms";
  static const String year_stale = "ys";
  static const String decade_stale = "Ds";
  static const String century_stale = "Cs";
  static const String millenium_stale = "Ms";
}

class Legal {
  static const String received_copyright_notices = "rcn";
  static const String received_trademark_notices = "rtn";
  static const String times_audio_file_reported = "tar";
  static const String times_image_file_reported = "tir";
  static const String times_text_reported = "ttr";
}

class DuplicateChild {
  static const String ids = "ids";
}

class Following {
  static const String following = "fw";
  static const String follower = "fr";
  static const String timestamp_followed = "tf";
}

class Username {
  static const String username = "n";
  static const String uid = "d";
}

class RTDB {
  static const String username = "n";
  static const String metrics = "m";
  static const String users = "u";
  static const String lists = "l";
}

class FunctionParams {
  static const String email = "e";
  static const String email_confirmation = "ec";
  static const String password = "p";
  static const String password_confirmation = "pc";
}

class ErrorCodes {
  static const String invalid_username = "iu";
  static const String invalid_email = "ie";
  static const String emails_dont_match = "ed";
  static const String invalid_uid = "id";
  static const String invalid_pswd = "ip";
  static const String pswds_dont_match = "pd";
  static const String mission_failed = "mf";
  static const String internal = "internal";
}

// collection names
class Coll {
  static const String sounds = "s";
  static const String users = "u";
  static const String lists = "l";
  static const String usernames = "n";
}

class StoragePaths {
  static const String sound = "s";
  static const String list = "l";
  static const String user = "u";
  static const String sound_file_name = "a";
  static const String list_image_name = "i";
  static const String user_image_name = "i";
}

class Lengths {
  static const int min_description_length = 1;
  static const int max_description_length = 420;
  static const int min_username_length = 4;
  static const int max_username_length = 17;
  static const int min_uid_length = 7;
  static const int max_uid_length = 21;
  static const int min_tag_length = 3;
  static const int max_tag_length = 17;
  static const int max_sound_tags = 3;
  static const int min_pswd_length = 5;
  static const int max_pswd_length = 100;
  static const int min_sound_name_length = 3;
  static const int max_sound_name_length = 27;
  // max file size is 2.5 MB
  static const int max_sound_file_size_bytes = 2500000;
  static const int max_sound_duration_millis = 30000;
}
