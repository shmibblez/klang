# list doc structure
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
    - image file bucket: string - (cloud storage bucket)
    - image file path: string - (cloud storage path)
- properties
  - explicit: bool
  - hidden: bool
  - search keys: string - (for checking whether list is explicit or hidden. There are 4 possible keys: "hidden & explicit", "hidden & not_explicit", "not_hidden & explicit", "not_hidden & not_explicit")
  - random seeds: {[int]: double} - (for random searches, key is random seed num, there will be 4 random seeds. Will have following structure: {1: [random num], 2: [random num], 3: [random num], 4: [random num]})
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

## list doc general stuff
- any time list doc is updated, random seeds are too, for randomization purposes

## legal
legal process is as follows:
- when user receives legal notice, they have 4 days to respond. If they respond during this time period, they won't receive punishment. To respond user can:
  - send counter notice
  - if name infringing, change name
  - if image file infringing, replace image
  - delete list
- if user doesn't respond during 4 day time period, if image infringing then image will be removed, & if name infringing list will be moved to quarantine, user doc "received [copyright or trademark] notices" & "times [image file, audio file, or text] reported" will increment, & "cant upload [image file, audio file, or text] until" will be incremented accordingly. If user has received more than 3 violations:
  - if can't upload until is in future, then add (2 days) to timestamp
  - if can't upload until isn't set or already passed, set to (current timestamp) + (# of violations) * (2 days)
- while list is in quarantine, user can still:
  - send counter notice
  - if name infringing, change name
  - if image file infringing, replace image
  - delete list
- if counter notice is sent, list will be moved back, and reprimands will be undone (will undo incremented user doc fields & will remove (2 days) from "cant upload _ until"), notice will be considerend resolved, & notice sender will be notified. Message sent to notice sender will say something like "User has sent a counter notice, we have to revert changes. Any further requests will have to be pursued legally. Upon reception of a court order to remove said content we can't really do anything else"
- if user changes name or deletes list while list is in quarantine, their punishment won't be undone, but the list will be resurrected
- if court order is received to remove content afterwards, then need to remove & punish user. This guarantees that list was uploaded illegally, so remove is only option, no quarantine this time.

