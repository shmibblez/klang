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
export function isPswdOk(p: unknown) {
  return typeof p == "string" && Rex.password_regex.test(p);
}

/**
 * regex for checking values
 */
export class Rex {
  static readonly username_regex = /^[a-zA-Z0-9_-]{4,17}$/; // checks if chars allowed and within allowed length
  static readonly email_regex = /^([-!#-'*+/-9=?A-Z^-~]+(\.[-!#-'*+/-9=?A-Z^-~]+)*|"(\[]!#-[^-~\s\t]|(\\[\t\s-~]))+")@[0-9A-Za-z]([0-9A-Za-z-]{0,61}[0-9A-Za-z])?(\.[0-9A-Za-z]([0-9A-Za-z-]{0,61}[0-9A-Za-z])?)+$/; // checks basic allowed email format
  static readonly uid_regex = /^[A-Za-z0-9]{5,28}$/; // checks if chars allowed and within allowed length
  static readonly password_regex = /^.{5,100}$/; // checks if within allowed length
}
