// ignore_for_file: non_constant_identifier_names

class KlangRegex {
  static final RegExp email = RegExp("(.+)@(.+){2,}\.(.+){2,}");
  // chars not allowed in username
  static final RegExp username_banished_chars = RegExp("[^a-zA-Z0-9_-]");
  // chars not allowed in uid
  static final RegExp uid_banished_chars = RegExp("[^A-Za-z0-9]");
}
