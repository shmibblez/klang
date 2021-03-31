# klang

klang is an app for sharing sounds. There are ringtone sounds, metronome sounds, etc.

klang means sound in german

# app structure
- app will have main page/navigator that houses tabs (home, search, etc) in bottom nav, and has appbar with settings
- each tab will have a child navigator that has pages, each one with its own stack
- root parent is a loading screen that checks if user signed in or not. Also stores provider with user info if logged in. This provider is passed down to all child navigators so it can be accessed from page context
- pages are in charge of handling sign in info, ex: profile page shows log in if user not logged in, also needs to handle sign up if user doesn't have account
  - need to check if user signed in every time user page is shown, ex: user is in signup page, log in page is in stack before it, and user signs up. When signup is complete, need to make sure that user page showing login refreshes & shows user profile after being recovered from navigator stack

# sound doc structure
- info
  - id: string
  - name: string
  - tags: string[] - (for filtering searches)
  - description: string - (optional)
  - source url: string - (optional)
  - creator id: string
  - timestamp created: Timestamp
  - timestamp updated: Timestamp
  - storage
    - sound file bucket: string - (cloud storage bucket)
    - sound file path: string - (cloud storage path)
- properties
  - explicit: bool
  - hidden: bool
  - search keys: string
  - random seeds: {[int]: double} - (for random searches, key is random seed num, there will be 4 random seeds) - (will have following structure: {1: [random num], 2: [random num], 3: [random num], 4: [random num]})
- search keys
  - search keys: {[key]: true}
  - timestamp updated: Timestamp - (for algorithm versioning)
- metrics (all follow same structure)
  - soonest stale: Timestamp - (smallest stale timestamp, for rejuvinating stale metrics)
  - downloads
    - total: int - (all time)
    - timestamp updated: Timestamp
    - this week: int
    - this month: int
    - this year: int
    - this decade: int
    - this century: int
    - this millenium: int
    - week stale: Timestamp - (timestamp downloads are stale, after this timestamp downloads will be set to 0. If metrics updated after this, means stale function hasn't caught it yet. In this case need to set to 0, and update stale timestamp to next time period end)
    - month stale: Timestamp
    - year stale: Timestamp
    - decade stale: Timestamp
    - century stale: Timestamp
    - millenium stale: Timestamp
  - saves
    - ...
  - parent lists (number of parent lists)
    - ...
  - best (combination of all metrics)
    - ...
- legal (legal information, if has received copyright notices before & not removed chances are it's not infringing) 
  - received copyright notices: int
  - received trademark notices: int

## sound doc general stuff
- any time sound doc is updated, random seeds are too, for randomization purposes

## sound doc tags
- sound tags keep track of what type of sound a sound is, and allow filtering sounds when searching
- sounds can have between 1-4 tags, and tags are indexed to allow filtering
- example indexing: tags: ringtone, message_sound, epic | indexes: [ringtone, message_sound, epic, epic|message_sound, epic|ringtone, message_sound|ringtone, epic|message_sound|ringtone]
  - all possible tag combos are created, with multiple ones being called composite tags. Composite tags allow for filtering sounds that match multiple tags, and are created from multiple tags in alphabetical order to limit possibilities

## metric updates
- metric updates are stored in rtdb, refer to rtdb structure. Metric report is as follows:
  - 
- metric updates are stored in rtdb, and are accompanied by timestamp for ascending filtering, & for determining stale timestamp for sound doc. rtdb metric update process is as follows:
  - push whether added (true) or removed (false) with push id as key (uid for downloads to prevent duplicates) to metric child tree, and push earliest timestamp (timestamp metric updated by user) to timestamp start. This timestamp will be used to determine stale timestamp if not already determined
- rtdb children have triggers that update sound doc metric if reached certain threshold or if random condition met (maybe ±5 downloads or if random condition met). There are also rtdb periodic functions that query for child metrics, ordering them (by what?) so oldest metrics get updated. Process for updating sound doc is as follows:
  - if stale timestamp not set, it means this is first metric update for time period -> need to determine timestamp metric will be stale, taking into account overflow (if metric received at end of time period), and set metric. If stale timestamp set, then simply update metric. This needs to be done for each metric.
note: rtdb stores "new metrics", and firestore doc stores current metrics
- stale metrics are rejuvinated by a periodic function. Rejuvination process is as follows:
  - if doc is found containing stale metrics (timestamp stale <= current timestamp), stale timestamp for time period is deleted, and metric is set to 0 (it's reset)

## sound doc queries
### bestest, all descending (composite)
| params                                                                 | filters                                                                                            |
| ---------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| hidden & explicit filters, tag filters, order by best of all-time      | ("in"), ("array-contains" info.tags.[tag key]), ("orderBy" on metrics.best.total           "desc") |
| hidden & explicit filters, tag filters, order by best of the week      | ("in"), ("array-contains" info.tags.[tag key]), ("orderBy" on metrics.best.this_week       "desc") |
| hidden & explicit filters, tag filters, order by best of the month     | ("in"), ("array-contains" info.tags.[tag key]), ("orderBy" on metrics.best.this_month      "desc") |
| hidden & explicit filters, tag filters, order by best of the year      | ("in"), ("array-contains" info.tags.[tag key]), ("orderBy" on metrics.best.this_year       "desc") |
| hidden & explicit filters, tag filters, order by best of the decade    | ("in"), ("array-contains" info.tags.[tag key]), ("orderBy" on metrics.best.this_decade     "desc") |
| hidden & explicit filters, tag filters, order by best of the century   | ("in"), ("array-contains" info.tags.[tag key]), ("orderBy" on metrics.best.this_century    "desc") |
| hidden & explicit filters, tag filters, order by best of the millenium | ("in"), ("array-contains" info.tags.[tag key]), ("orderBy" on metrics.best.this_millenium  "desc") |
### most downloads, all descending (composite)
| params                                                                           | filters                                                                                                      |
| -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| hidden & explicit filters, tag filters, order by most downloads of all-time      | ("in"), ("array-contains" info.tags.[tag key]), ("orderBy" on metrics.most_downloads.total           "desc") |
| hidden & explicit filters, tag filters, order by most downloads of the week      | ("in"), ("array-contains" info.tags.[tag key]), ("orderBy" on metrics.most_downloads.this_week       "desc") |
| hidden & explicit filters, tag filters, order by most downloads of the month     | ("in"), ("array-contains" info.tags.[tag key]), ("orderBy" on metrics.most_downloads.this_month      "desc") |
| hidden & explicit filters, tag filters, order by most downloads of the year      | ("in"), ("array-contains" info.tags.[tag key]), ("orderBy" on metrics.most_downloads.this_year       "desc") |
| hidden & explicit filters, tag filters, order by most downloads of the decade    | ("in"), ("array-contains" info.tags.[tag key]), ("orderBy" on metrics.most_downloads.this_decade     "desc") |
| hidden & explicit filters, tag filters, order by most downloads of the century   | ("in"), ("array-contains" info.tags.[tag key]), ("orderBy" on metrics.most_downloads.this_century    "desc") |
| hidden & explicit filters, tag filters, order by most downloads of the millenium | ("in"), ("array-contains" info.tags.[tag key]), ("orderBy" on metrics.most_downloads.this_millenium  "desc") |
### random sounds (composite)
| params                                                           | filters                                                                                |
| ---------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| hidden & explicit filters, filter by tags, order by random seeds | ("in"), ("array-contains" tags), ("orderBy" randomSeeds.[1, 2, 3, or 4] "asc or desc") |


# rtdb structure
- metrics
  - sounds - (same for all objects, only difference is actual metrics)
    - sound id
      - saves - (same for all metrics)
        - timestamp start - (stores earliest timestamp before sound doc updated) (ok to store with uids since always different lengths, also makes cleanup after update easier since deletes everything)
          - [push id]: Timestamp - (timestamp user updated metric, smallest one is only important one & will be listed first)
        - [push id]: bool - (true if added, false if removed)
      - downloads - (only one that uses uid, to prevent duplicate entries)
        - ...
        - [user id]: bool - (can only be true -> can't un-download something)
      - parent lists
        - ...
      - other metric
        - ...
  - users
    - ...
  - lists
    - ...

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
