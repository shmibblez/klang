import 'package:firebase_auth/firebase_auth.dart';

enum LoginResult {
  success,
  invalid_email,
  wrong_password,
  user_disabled,
  user_not_found,
}

class FirePP {
  /// returns [LoginResult] if something went wrong
  static Future<LoginResult> login(String email, String password) async {
    // TODO: login with auth, update LoginResult enum based on error codes

    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      switch ((e as FirebaseAuthException).code) {
        case "invalid-email":
          return LoginResult.invalid_email;
        case "user-disabled":
          return LoginResult.user_disabled;
        case "user-not-found":
          return LoginResult.user_not_found;
        case "wrong_password":
          return LoginResult.wrong_password;
        default:
          throw "unknown FirebaseAuthException error code: \"${(e as FirebaseAuthException).code}\"";
      }
    }

    return LoginResult.success;
  }
}
