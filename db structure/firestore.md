# firestore structure
- root
  - sounds - (collection)
    - [sound doc id] - (doc)
      - lists - (collection)
        - [sound doc num] - (doc)
      - saves - (collection)
        - [sound doc num] - (doc)
  - users - (collection)
    - [user doc id] - (doc)
      - saved - (collection)
        - saved sounds - (doc)
        - saved lists - (doc)
  - lists - (collection)
    - [list doc id] - (doc)
      - saves - (collection)
        - [list doc num] - (doc)

## sounds.[sound doc id].lists & sounds.[sound doc id].saves sub-collections
- these collections store docs that store sound doc duplicates along with list of list ids & save ids. This means that doc id needs to be random, & need to keep track of which docs are full & which ones aren't
- this allows collection group querying for sounds in lists & ordering by downloads, saves, timestamp created, etc, and allows lists & saved lists to have unlimited size. (see user saved lists & saved sounds for note on those limits)

## users.[user doc id].saved sub-collection
- here is where user saved sounds & lists docs are stored. These store the sounds & lists a user has saved
- since these need to be cached locally (for checking whether to show option to save or unsave content afap), there is a limit on how many items can be saved. This limit needs to be determined based on storage calculations, but will be 100 initially. Saved items are stored along with timestamp so user can also order saved items based on time they saved them.