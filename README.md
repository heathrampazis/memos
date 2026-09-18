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
