# klang

klang is an app for sharing sounds. There are ringtone sounds, metronome sounds, etc.

klang means sound in german

This was meant to be published to the google play store, but it was eventually abandoned due to lack of time because of university classes. This app however was functional, and although not 100% complete, it strengthened my understanding of Flutter, Dart, and non-relational databases thanks to firestore.

# app structure
- app will have main page/navigator that houses tabs (home, search, etc) in bottom nav, and has appbar with settings
- each tab will have a child navigator that has pages, each one with its own stack
- root parent is a loading screen that checks if user signed in or not. Also stores provider with user info if logged in. This provider is passed down to all child navigators so it can be accessed from page context
- pages are in charge of handling sign in info, ex: profile page shows log in if user not logged in, also needs to handle sign up if user doesn't have account
  - need to check if user signed in every time user page is shown, ex: user is in signup page, log in page is in stack before it, and user signs up. When signup is complete, need to make sure that user page showing login refreshes & shows user profile after being recovered from navigator stack

# nav structure
- there is a root page that has bottom nav - there is only 1 instance
- there are other pages that can originate from this root page, but they're fullscreen
- this allows navigating to pages from url

# db requests
- app calls function, function gets db data & sends to app - this happens for every data request
  - this is much more flexible since allows filtering data & only getting specific fields which is especially important, for example, when querying for saved sounds (not from saved sounds id list)

# other stuff
## requests
- any app user (authenticated & !authenticated) can send requests or feedback by email. Requests can be anything related to the app that doesn't have a dedicated form. Like for example deleting lists or sounds after user deleted their account

<!--
A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
-->
# important
- doc ids can't match the regular expression `__.*__`
  - need to add this check to fields that check/generate doc ids (user doc (uid), and sound name)
  - could add special character before doc ids so all ids would be valid, ex: id would be "i__epic__" instead of "\__epic__"
- need to make sure create account catches duplicate usernames
- 

# checklist
| stuff to do          | server side | client side | tested | notes |
| -------------------- | ----------- | ----------- | ------ | ----- |
| navigation           | 🚫           | ✅           |        |       |
| play sound           | 🚫           | ✅           |        |       |
| user sign up         | ✅           | ✅           |        |       |
| user sign in         | 🚫           | ✅           |        |       |
| create sound         | ✅           | ✅           |        |       |
| search for sound     | ✅           | ✅           |        |       |
| search for user      | ✅           | ✅           |        |       |
| set user image       | ❌           | ❌           |        |       |
| save sound           | ✅           | ✅           |        |       |
| unsave sound         | ✅           | ✅           |        |       |
| view saved sounds    | 🚫           | ✅           |        |       |
| edit sound           | ❌           | ❌           |        |       |
| sound metric updates | ❌           | 🚫           |        |       |
| user metric updates  | ❌           | 🚫           |        |       |
| follow user          | ❌           | ❌           |        |       |
| unfollow user        | ❌           | ❌           |        |       |
| content reporting    | ❌           | ❌           |        |       |
| delete user          | ❌           | ❌           |        |       |


# future features
| stuff to do          | done server side | done client side | notes                                     |
| -------------------- | ---------------- | ---------------- | ----------------------------------------- |
| lists                | not yet          | not yet          |                                           |
| set list image       | not yet          | not yet          |                                           |
| create / update list | not yet          | not yet          |                                           |
| add sound to list    | not yet          | not yet          |                                           |
| deleted user cleanup | not yet          | not yet          | can be done if storage costs get too high |
