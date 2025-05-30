// // Start writing Firebase Functions
// // https://firebase.google.com/docs/functions/typescript
//
// export const helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// import functions = require("firebase-functions");
// The Firebase Admin SDK to access Firestore.
import * as admin from "firebase-admin";
admin.initializeApp();

// export functions
export { create_user as cu, get_saved_items as gsi } from "./user";
export { create_sound as cs } from "./storage";
export { search as s } from "./search";
export {
  save_sound as ss,
  on_sound_update as osu,
  unsave_sound as us,
} from "./item_clones";

// FIXME: only for testing
export { create_test_sounds as _cts } from "./testing";
