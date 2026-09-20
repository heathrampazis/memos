# Memos

A note app for iPhone. Eight tiles, one screen, no scrolling — the cap is the
product, not a limitation waiting to be lifted.

Built with SwiftUI and SwiftData, iOS 18 and up.

## Layout

```
Memos/
├─ App/          entry point, settings, the SwiftData container
├─ Design/       palettes, type ramp, spacing — no logic, no models
├─ Models/       Tile and the blocks that make up its body
├─ Components/   reusable views that know nothing about a Tile
├─ Extensions/
└─ Features/
    ├─ Home/     the board of eight tiles
    ├─ Editor/   the tile editor, its tray, and every widget
    └─ Settings/
```

Two rules keep it that way:

**Components never take a model.** `StickyCard` takes a colour, a tilt and some
content — not a `Tile`. That is why the same card renders the board, the colour
picker's swatches and a home screen widget without any of them inventing a fake
Tile to pass in.

**Design holds no logic.** Every colour comes from `TilePalettes`, every size
from `Spacing`, every font from `Typography`. A magic number in a view is a bug.

## The board

Eight fixed places, laid out as one `ZStack` of positioned cards rather than a
stack of rows — a tile dragged between rows has to stay in the same container
or SwiftUI reads the move as a delete and an insert. Holding a tile starts
arrange mode: everything wobbles, each grows an (x), and tiles can be carried
to a new place. Order lives in `Tile.sortIndex`.

## The editor

See `Memos/Features/Editor/README.md`. The short version: a tile's body is an
ordered list of segments — runs of text and widgets — and everything else
follows from that.

## Storage

`Tile` is the only `@Model`. Its body is a list of segments encoded by
`TileCodec`; anything too large to sit in a note (recordings, sketches, photos,
bookmark thumbnails) lives in its own file store under Application Support,
with the note keeping only an id.

`ModelContainerFactory` rebuilds the store from scratch in debug builds when a
schema change stops it opening. That is deliberate while the shape is still
moving, and wants replacing with a migration plan before anyone's notes matter.

## Legal and the App Store

`docs/` is the public site, served by GitHub Pages: the privacy policy App Review
requires, and a support page for the Support URL the store listing asks for. Both
addresses are also compiled into the app in `Legal.swift`, because guideline
5.1.1(i) wants the privacy policy reachable from inside the app and not only from
the listing. Change a URL in one place and the other must follow.

`PrivacyInfo.xcprivacy` declares that the app tracks nobody, collects nothing,
and touches one required-reason API: `UserDefaults`, for the appearance and
palette settings, under reason `CA92.1`. Adding any of the other required-reason
APIs — file timestamps, disk space, system boot time, active keyboards — means
adding it there too, or the upload comes back as `ITMS-91053`.

Export compliance is answered up front by `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption`,
which is true only while the app has no cryptography of its own. HTTPS, which is
all the bookmark fetch uses, is exempt.
