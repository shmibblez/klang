import { HttpsError } from "firebase-functions/lib/providers/https";
import { ErrorCodes } from "./constants";

export class InvalidUsernameError extends HttpsError {
  constructor(details?: string) {
    super("invalid-argument", ErrorCodes.invalid_username, details);
  }
}
export class InvalidEmailError extends HttpsError {
  constructor(details?: string) {
    super("invalid-argument", ErrorCodes.invalid_email, details);
  }
}
export class EmailsDontMatchError extends HttpsError {
  constructor(details?: string) {
    super("invalid-argument", ErrorCodes.emails_dont_match, details);
  }
}
export class InvalidUidError extends HttpsError {
  constructor(details?: string) {
    super("invalid-argument", ErrorCodes.invalid_uid, details);
  }
}
export class InvalidPswdError extends HttpsError {
  constructor(details?: string) {
    super("invalid-argument", ErrorCodes.invalid_pswd, details);
  }
}
export class PswdsDontMatchError extends HttpsError {
  constructor(details?: string) {
    super("invalid-argument", ErrorCodes.pswds_dont_match, details);
  }
}
/**
 * error thrown when something failed unexpectedly
 */
export class MissionFailedError extends HttpsError {
  constructor(details?: string) {
    super("unknown", ErrorCodes.mission_failed, details);
  }
}
