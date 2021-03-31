# klang

klang is an app for sharing sounds. There are ringtone sounds, metronome sounds, etc.

klang means sound in german

# app structure
- app will have main page/navigator that houses tabs (home, search, etc) in bottom nav, and has appbar with settings
- each tab will have a child navigator that has pages, each one with its own stack
- root parent is a loading screen that checks if user signed in or not. Also stores provider with user info if logged in. This provider is passed down to all child navigators so it can be accessed from page context
- pages are in charge of handling sign in info, ex: profile page shows log in if user not logged in, also needs to handle sign up if user doesn't have account
  - need to check if user signed in every time user page is shown, ex: user is in signup page, log in page is in stack before it, and user signs up. When signup is complete, need to make sure that user page showing login refreshes & shows user profile after being recovered from navigator stack


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
# klang
