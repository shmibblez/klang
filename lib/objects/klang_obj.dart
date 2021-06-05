import 'package:klang/objects/klang_sound.dart';

abstract class KlangObj {
  static List<O> fromJsonArr<O extends KlangObj>(List list) {
    // TODO, implement for each KlangObj type
    if (O is KlangSound) {
      return KlangSound.fromJsonArr(list) as List<O>;
    }
  }
}
