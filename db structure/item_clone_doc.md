# lists & saved content sub docs
this doc is in content sub collection and stores list of content ids that store it.
- ex: sound doc has saves sub collection where clones of it with list of uids of users that have saved it
this doc is stored in paths:
- sounds.[sound doc id].lists
- sounds.[sound doc id].saves

# doc structure:
- [doc clone, may exclude fields not necessary for sorting]
- clone fields: map - (stores clone fields in here to separate fields and avoid conflicting field names)
  - ids: string[] - (content ids that have saved it)
  - space available: bool - (whether has space for more ids)

# notes
- content types that include doc are given by the sub collection, ex: sounds saved will always be in sounds.[sound id].lists -> lists include this sound