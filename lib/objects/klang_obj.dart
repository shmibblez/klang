import 'package:klang/objects/klang_sound.dart';
import 'package:klang/objects/klang_user.dart';

abstract class KlangObj {
  static List<O> fromJsonArr<O extends KlangObj>(List list) {
    if (O is KlangUser) {
      return KlangUser.fromJsonArr(list) as List<O>;
    } else if (O is KlangSound) {
      return KlangSound.fromJsonArr(list) as List<O>;
    }
    throw UnimplementedError(
      "fromJsonArr not implemented for KlangObj type: $O",
    );
  }
}
