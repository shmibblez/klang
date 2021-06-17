# sound doc structure
- info
  - id: string
  - name
    - name: string
    - search keys: {[key]: true}
    - timestamp updated: Timestamp - (for algorithm versioning & update limiting)
  - tags: string[] - (for filtering searches)
  - tag_keys: string[] - (tags indexed for searching)
  - description: string - (optional)
  - source url: string - (optional)
  - creator id: string
  - timestamp created: Timestamp
  - timestamp updated: Timestamp
  - storage
    - sound file bucket: string - (cloud storage bucket)
    - sound file path: string - (cloud storage path)
    - sound file duration: double - (duration in seconds)
- properties
  - explicit: bool
  - hidden: bool
  - search keys: string - (for checking whether sound is explicit or hidden. There are 4 possible keys: "hidden & explicit", "hidden & not_explicit", "not_hidden & explicit", "not_hidden & not_explicit")
  - random seeds: {[int]: double} - (for random searches, key is random seed num, there will be 4 random seeds. Will have following structure: {1: [random num], 2: [random num], 3: [random num], 4: [random num]})
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
### search keys (not composite since not ordering)
| params                                               | filters                                                   |
| ---------------------------------------------------- | --------------------------------------------------------- |
| hidden & explicit filters, tag filters, name filters | ("in"), ("array-contains" info.tags.[tag key]), (== keys) |
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

## sound doc search keys
sound doc search keys index sound names in the following way.
  - preparation
    - text is cleaned up, this is the text that is indexed by following phases
      - "NFKD" normalization to split diacritics & convert text that looks like letters to letters
      - all diacritics are removed
      - all emoji skin colors are removed
      - all variation selectors are removed
      - "NFKC" normalization to tidy up
      - trim & replace multiple spaces with 1
  - phase 1.0
    - graphemes are indexed individually
  - phase 1.1
    - composite emojis are split into individual ones, graphemes are indexed individually
  - phase 2.0
    - graphemes are indexed in pairs
  - phase 2.1
    - composite emojis are split into individual ones, graphemes are indexed in pairs
  - phase 3
    - anything that isn't in /[A-Za-z0-9\s_-]/ is filtered out, then trim & remove duplicate spaces, and index those grapheme/character pairs
  - phase 4
    - anything that isn't in /[A-Za-z0-9\s]/  is filtered out, then trim & remove duplicate spaces, and index those grapheme/character pairs

## legal
legal process is as follows:
- when user receives legal notice, they have 4 days to respond. If they respond during this time period, they won't receive punishment. To respond user can:
  - send counter notice
  - if name infringing, change name
  - if audio file infringing, delete sound
  - delete sound
- if user doesn't respond during 4 day time period, sound will be moved to quarantine, user doc "received [copyright or trademark] notices" & "times [image file, audio file, or text] reported" will increment, & "cant upload [image file, audio file, or text] until" will be incremented accordingly. If user has received more than 3 violations:
  - if can't upload until is in future, then add (2 days) to timestamp
  - if can't upload until isn't set or already passed, set to (current timestamp) + (# of violations) * (2 days)
- while sound is in quarantine, user can still:
  - send counter notice
  - if name infringing, change name
  - if audio file infringing, delete sound
  - delete sound
- if counter notice is sent, sound will be moved back, and reprimands will be undone (will undo incremented user doc fields & will remove (2 days) from "cant upload _ until"), notice will be considerend resolved, & notice sender will be notified. Message sent to notice sender will say something like "User has sent a counter notice, we have to revert changes. Any further requests will have to be pursued legally. Upon reception of a court order to remove said content we can't really do anything else"
- if user changes name or deletes sound while sound is in quarantine, their punishment won't be undone, but the sound will be resurrected
- if court order is received to remove content afterwards, then need to remove & punish user. This guarantees that sound was uploaded illegally, so remove is only option, no quarantine this time.