import { Lengths } from "./constants/constants";

import { URL } from "url";
import { https } from "firebase-functions";

export function isAuthorized(context: https.CallableContext): boolean {
  return (
    context.auth?.token?.email != undefined && context.auth?.uid != undefined
  );
}
export function isSoundExtensionOk(e: string) {
  return Lengths.supported_sound_file_extensions.includes(e);
}
export function isSoundNameOk(n: string) {
  return typeof n == "string" && Rex.username_regex.test(n);
}
/**
 *
 * @param n username
 * @returns whether username ok
 */
export function isUsernameOk(n: unknown): boolean {
  return typeof n === "string" && Rex.username_regex.test(n);
}
export function isEmailOk(e: unknown): boolean {
  return typeof e === "string" && Rex.email_regex.test(e);
}
export function isUidOk(uid: unknown): boolean {
  return typeof uid === "string" && Rex.uid_regex.test(uid ?? "");
}
export function isPswdOk(p: unknown): boolean {
  return typeof p == "string" && Rex.password_regex.test(p);
}
export function isDescriptionOk(d: unknown): boolean {
  return (
    typeof d == "string" &&
    (d.length >= 0 ||
      Lengths.max_description_length <= Lengths.max_description_length)
  );
}
export function isUrlOk(u: unknown): boolean {
  if (typeof u != "string") return false;
  if (u.length <= 0) return true;
  try {
    new URL(u);
    return true;
  } catch {
    return false;
  }
}
export function isTagOk(t: unknown) {
  return typeof t == "string" && Rex.tag_regex.test(t);
}
/**
 * regex for checking values
 */
export class Rex {
  static readonly username_regex = /^[a-zA-Z0-9_-]{4,17}$/; // checks if chars allowed and within allowed length
  static readonly email_regex =
    /^([-!#-'*+/-9=?A-Z^-~]+(\.[-!#-'*+/-9=?A-Z^-~]+)*|"(\[]!#-[^-~\s\t]|(\\[\t\s-~]))+")@[0-9A-Za-z]([0-9A-Za-z-]{0,61}[0-9A-Za-z])?(\.[0-9A-Za-z]([0-9A-Za-z-]{0,61}[0-9A-Za-z])?)+$/; // checks basic allowed email format
  static readonly uid_regex = /^[A-Za-z0-9-]{5,28}$/; // checks if chars allowed and within allowed length
  static readonly password_regex = /^.{5,100}$/; // checks if within allowed length
  static readonly tag_regex = /^[A-Za-z _-]{3,17}$/; // checks if chars allowed and within allowed length, still need to trim and remove duplicate spaces

  static readonly uid_banished_chars = /[^A-Za-z0-9-]/g;
  static readonly uid_allowed_chars = /[A-Za-z0-9-]/g;
}
