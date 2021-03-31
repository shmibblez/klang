# user doc structure
- info
  - id: string
  - name: string
  - tags: string[] - (for filtering searches)
  - tag history: {[tag]: int} - (stores which tags user has used & how many times. Most used ones only are indexed)
  - description: string - (optional)
  - creator id: string
  - timestamp created: Timestamp
  - timestamp updated: Timestamp
  - device tokens: string[] - (array of device tokens, for sending notifications)
  - storage
    - image file bucket: string - (cloud storage bucket)
    - image file path: string - (cloud storage path)
- properties
  - explicit: bool
  - hidden: bool
  - search keys: string - (for checking whether user profile is explicit or hidden. There are 4 possible keys: "hidden & explicit", "hidden & not_explicit", "not_hidden & explicit", "not_hidden & not_explicit")
  - random seeds: {[int]: double} - (for random searches, key is random seed num, there will be 4 random seeds. Will have following structure: {1: [random num], 2: [random num], 3: [random num], 4: [random num]})
- search keys
  - search keys: {[key]: true}
  - timestamp updated: Timestamp - (for algorithm versioning)
- metrics (all follow same structure)
  - soonest stale: Timestamp - (smallest stale timestamp, for rejuvinating stale metrics)
  - followers
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
  - following
    - ...
  - sounds created
    - ...
  - lists created
    - ...
  - best (combination of all metrics)
    - ...
- legal (legal information, if has received copyright notices before & not removed chances are it's not infringing) 
  - received copyright notices: int
  - received trademark notices: int
  - times audio file reported: int
  - times image file reported: int
  - times text reported: int
  - cant upload audio files until: Timestamp - (these depend on how many times content type reported)
  - cant upload image files until: Timestamp
  - cant upload text until: Timestamp

# user doc general stuff
- any time user doc is updated, random seeds are too, for randomization purposes
- pretty much all fields are same as sound doc, only differences are 
  - image files instead of sound files
  - legal fields & limitations
  - tags only contain tags user has used the most. This is stored in tag history. This is to prevent too many composite tag combos since there will be lots of them

## user doc queries
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
### random users (composite)
| params                                                           | filters                                                                                |
| ---------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| hidden & explicit filters, filter by tags, order by random seeds | ("in"), ("array-contains" tags), ("orderBy" randomSeeds.[1, 2, 3, or 4] "asc or desc") |

## legal
legal process
- when user receives legal notice, they have 7 days to respond. If they respond during this time period, they won't receive punishment. To respond user can:
  - send counter notice
  - if username infringing, change username
  - if image infringing, change image
- if user doesn't respond during 7 day time period, image will be removed or username will be randomized, "received [copyright or trademark] notices" & "times [image file, audio file, or text] reported" will increment, & "cant upload [image file, audio file, or text] until" will be incremented accordingly. If user has received more than 3 violations:
  - if can't upload until is in future, then add (2 days) to timestamp
  - if can't upload until isn't set or already passed, set to (current timestamp) + (# of violations) * (2 days)
- in this case user can't respond after 7 day period since changes will be un-revertable
- if user sends counter notice, notice will be considered resolved, & notice sender will be notified. Message sent to notice sender will say something like "User has sent a counter notice, we have to revert changes. Any further requests will have to be pursued legally. Upon reception of a court order to remove said content we can't really do anything else"