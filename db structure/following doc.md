# following doc structure
- follower: string - (uid of user that is following other user. This doc is in this user's following sub collection)
- following: string - (uid of user that is being followed)
- timestamp followed: Timestamp (Timestamp that follower followed following)

## general stuff
- users only store which users they follow. 
- to see who they follow, they simply query in their following sub-collection
- to see who follows them, they need to perform collection-group query in following sub-collection where their id is in following field
- both queries can be ordered by timestamp, can't order by username though, that would require storing username in user doc & having structure similar to saved sounds, which would get out of hand when
- can also order who they follow by name & timestamp created, by querying in followees' follower subcollections where uid is in array

## follow process
- when user1 follows user2, all docs are updated via transaction, and following count is incremented directly, no need for counter in rtdb. Transaction does following:
  - doc with user2's id is created in user1's following sub-collection
  - following metric in user1's doc is incremented
  - user1's id is added to a doc in user2's follower sub-collection
- after transaction complete, rtdb pushes id to user2's follower count with true value (represents follow)

## unfollow process
- when user1 unfollows user2, same as follow process. Transaction does following:
  - doc with user2's id is deleted from user1's following sub-collection
  - following metric in user1's doc is decremented
  - user1's id is removed from doc in user2's follower sub-collection
- after transaction complete, rtdb pushes id to user2's follower count with false value (represents unfollow)