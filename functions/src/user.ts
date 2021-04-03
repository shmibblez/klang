import * as functions from "firebase-functions";
import { FunctionParams, Info } from "./constants/constants";
import {
  EmailsDontMatchError,
  InvalidEmailError,
  InvalidPswdError,
  InvalidUidError,
  InvalidUsernameError,
  PswdsDontMatchError,
} from "./constants/errors";
import { isEmailOk, isPswdOk, isUidOk, isUsernameOk } from "./field_checks";

export const setEmailKey = functions.https.onCall((data, context) => {
  data;
  context;
  /**
   * {@link email verification (add later, for now, just check if email matches regex (not strict))
   *  - when user is signing up, they need to verifiy their email
   *    - client:
   *      - on client, when user enters email, show button to validate, and field to enter key below
   *      - when validate email button is pressed, call this function with email as param
   *    - server (this function):
   *      - when email is received, add to rtdb pendingEmails child as: "[encodedEmail]: [verification code]" (IMPORTANT: need to encode email since some chars not valid for rtdb field paths)
   *      - send code to user's email
   *      - make sure that email key matches in rtdb during sign-up process
   * }
   */
});

/**
 * create user
 *
 * data - (if any null or invalid, throw error, unless specified below)
 * - username
 * - email
 * - email confirmation
 * - uid - if null then doesn't matter, if not null check if valid
 * - password
 * - password confirmation
 *
 * procedure
 * 1. check data
 * 2. create auth instance
 * 3. create rtdb username
 * 4. create user doc
 * - in any case, inform failure & undo stuff that succeeded
 */
export const create_user = functions.https.onCall(async (data, ctxt) => {
  const raw_username: unknown = data[Info.item_name];
  const raw_uid: unknown = data[Info.id] ?? null;
  const raw_email: unknown = data[FunctionParams.email];
  const raw_email_conf: unknown = data[FunctionParams.email_confirmation];
  const raw_pswd: unknown = data[FunctionParams.password];
  const raw_pswd_conf: unknown = data[FunctionParams.password_confirmation];

  if (!isUsernameOk(raw_username)) throw new InvalidUsernameError();
  if (!isEmailOk(raw_email)) throw new InvalidEmailError();
  if (raw_email != raw_email_conf) throw new EmailsDontMatchError();
  if (raw_uid != null && !isUidOk(raw_uid)) throw new InvalidUidError();
  if (!isPswdOk(raw_pswd)) throw new InvalidPswdError();
  if (raw_pswd != raw_pswd_conf) throw new PswdsDontMatchError();

  const createAuthPromise = 0; // create auth instance
  const setUsernamePromise = 0; // set username in rtdb here
  const createUserDocPromise = 0; // create user here

  // perform all operations asynchronously, and if any failed undo successful ones. Order is maintained so
  const ops = await Promise.allSettled([
    createAuthPromise,
    setUsernamePromise,
    createUserDocPromise,
  ]);
  const failed_ops: number[] = [];
  const success_ops: number[] = [];
  ops.forEach((op, i) => {
    if (op.status === "rejected") {
      failed_ops.push(i);
    } else if (op.status === "fulfilled") {
      success_ops.push(i);
    }
  });

  if (failed_ops.length > 0) {
    const undo_promises: Promise<any>[] = [];
    for (const i of success_ops) {
      switch (i) {
        case 1:
          // undo here
          break;

        case 2:
          // undo here
          break;
      }
    }
    // undo successful ops
    await Promise.all(undo_promises);
    throw new UnknownError();
  }
});
