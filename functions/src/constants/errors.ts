import { HttpsError } from "firebase-functions/lib/providers/https";
import { ErrorCodes } from "./constants";

export class UnauthenticatedError extends HttpsError {
  constructor(details?: string) {
    super("unauthenticated", ErrorCodes.unauthenticated, details);
  }
}
export class UidTakenError extends HttpsError {
  constructor(details?: string) {
    super("already-exists", ErrorCodes.uid_taken, details);
  }
}
export class EmailTakenError extends HttpsError {
  constructor(details?: string) {
    super("already-exists", ErrorCodes.email_taken, details);
  }
}
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
export class NoSoundError extends HttpsError {
  constructor(details?: string) {
    super("invalid-argument", ErrorCodes.no_sound, details);
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
