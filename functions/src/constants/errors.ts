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
export class InvalidSoundNameError extends HttpsError {
  constructor(details?: string) {
    super("invalid-argument", ErrorCodes.invalid_sound_name, details);
  }
}
export class InvalidDocIdError extends HttpsError {
  constructor(details?: string) {
    super("invalid-argument", ErrorCodes.invalid_doc_id, details);
  }
}
export class UnsupportedFileExtensionError extends HttpsError {
  constructor(details?: string) {
    super("invalid-argument", ErrorCodes.unsupported_file_extension, details);
  }
}
export class SoundDurationTooLongError extends HttpsError {
  constructor(details?: string) {
    super("invalid-argument", ErrorCodes.sound_duration_too_long, details);
  }
}
export class NoSoundError extends HttpsError {
  constructor(details?: string) {
    super("invalid-argument", ErrorCodes.no_sound, details);
  }
}
export class FileTooBigError extends HttpsError {
  constructor(details?: string) {
    super("invalid-argument", ErrorCodes.file_too_big, details);
  }
}
export class UnsupportedQueryError extends HttpsError {
  constructor(details?: string) {
    super("invalid-argument", ErrorCodes.unsupported_query, details);
  }
}
export class NonexistentDocError extends HttpsError {
  constructor(details?: string) {
    super("failed-precondition", ErrorCodes.nonexistent_doc, details);
  }
}
export class AlreadySavedError extends HttpsError {
  constructor(details?: string) {
    super("failed-precondition", ErrorCodes.already_saved, details);
  }
}
export class NotSavedError extends HttpsError {
  constructor(details?: string) {
    super("failed-precondition", ErrorCodes.not_saved, details);
  }
}
export class LimitOverflowError extends HttpsError {
  constructor(details?: string) {
    super("failed-precondition", ErrorCodes.limit_overflow, details);
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
