// content type
enum KlangContentType { user, sound }

const Map<KlangContentType, String> KlangContentTypeToStr = {
  KlangContentType.user: "user",
  KlangContentType.sound: "sound",
};

const Map<String, KlangContentType> KlangContentTypeFromStr = {
  "user": KlangContentType.user,
  "sound": KlangContentType.sound,
};
