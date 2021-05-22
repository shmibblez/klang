class KlangRegex {
  static final RegExp email = RegExp("(.+)@(.+){2,}\.(.+){2,}");
  static final RegExp username = RegExp("^[a-zA-Z0-9_-]{4,17}");
  static final RegExp uid = RegExp("^[A-Za-z0-9]{5,28}");
}
