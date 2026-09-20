# The editor

## A tile's body is a list of segments

```swift
[TileSegment]   // a run of text, a voice memo, a run of text, a table, …
```

A `TileSegment` is either a run of rich text or exactly one widget. That single
decision is where most of the editor's behaviour comes from.

Widgets were attachments inside one text view first. They did not render, the
text was full of object-replacement characters, and numbering and deletion both
had to be kept in sync by hand. Segments replaced that: a widget is a real
SwiftUI view, and a run of text ends wherever one begins.

The whole thing is still one scroll, so it reads as a single page.

## Adding a widget

1. A block type in `Models/` — `id`, whatever the widget needs, `isEmpty`.
2. A case on `TileSegment` (property, initialiser, `isText`, `isEmptyWidget`)
   and on `TileCodec.Entry`, `decode`, `encode` and `plainText`.
3. A card in `Features/Editor/Widgets/`, taking a `Binding` to its block and a
   `TileColor`.
4. A case in `WidgetChoice` so it appears in the (+) menu.
5. A branch in `TileEditorView.runs`, and an `add…` method.
6. If it keeps files on disk, a store beside the others and a line in
   `WidgetStore.delete`.

Nothing else. Delete mode, backspace-merge, the board preview and saving all
come free.

## Segment surgery

`Models/TileSegments.swift` holds the operations as extensions on the array —
splitting a run to make room for a widget, joining two runs when one goes away,
and making sure a tile always starts and ends with somewhere to type. None of it
touches SwiftUI, so it reads as what it is.

Joins always merge *into* the lower run. The text view holding the caret has to
survive the merge, or the keyboard drops and comes back on every backspace.

## The tray

One bar at the bottom whose contents follow the caret: formatting while writing,
panel kinds inside a panel, a symbol row inside a code block, row and column
controls inside a table, and nothing at all when nothing is focused. The
floating (+) is not part of it — it swaps the tray for the widget menu.

Each mode reads its focus by looking the segment up in the tile. A card's own
focus state dies with the card, so trusting it leaves the tray offering table
controls for a table that was deleted.

## Text, and the two things that bite

Text is one `UITextView` per run, wrapped by `RichTextView`. Two hazards worth
knowing before changing anything here:

**UIKit rebuilds `typingAttributes` whenever the selection moves**, from the
text around the caret, and it does not carry custom attribute keys across.
Anything set around a selection change has to be re-asserted, usually on the
next runloop pass.

**Levels, lists and ticks belong to a paragraph; bold, italic and underline
belong to characters.** Read a level from the character behind the caret and an
empty line reports whatever the paragraph above it was — which is how a quote's
indent used to follow the caret out of the quote. Styling also stops short of
the line break that ends a paragraph, so a level cannot leak onto the next line.

List markers and the quote rule are drawn in `EditorTextView`, never inserted as
text. The note then holds exactly what was typed: nothing to renumber, no marker
anyone can half-delete, and clean previews and search.

## Rearranging a widget

Holding a widget puts the note into edit mode and the same hold carries it — one
finger, no lifting. `DeletableWidget` does that with two gestures rather than one
composed of both, and the reason is worth keeping:

- A bare `LongPressGesture`, high priority, decides that a hold happened. High
  priority is what cancels the tap already in flight underneath, so the finger
  lifting after a hold no longer opens the drawing editor. It is half a second
  and fails on 8 points of travel, because once a hold is granted the page can no
  longer scroll under it, so it must not be cheap to win.
- A separate `DragGesture`, simultaneous, does the carrying. It is attached from
  the start and ignores everything until the press arms it — a gesture switched
  on with edit mode would be added to a finger already down and never see it, and
  ignoring the touch until armed is what leaves a swipe free to scroll.

Composing the two with `sequenced` is the obvious move and it fails twice over:
the pair claims every touch the widget gets, so nothing inside one can be tapped,
and `.first` reports the press being *attempted* from touch-down rather than
landing, so the note wobbles the instant a widget is touched.

The move itself does not work on segments. `[TileSegment].blocks` flattens the
note into one list of paragraphs and widgets, the widget moves inside that list,
and `from(blocks:)` rebuilds the segments — so the runs of text either side join
or split as a consequence rather than as bookkeeping. A widget can therefore land
between any two lines of writing, not just beside another widget.

`SegmentGeometry` holds where each segment sits and the text view behind each
run: the frames find what is under the finger, the views answer which line of a
run it is on. Both are needed because a run of text is many drop targets in one
view.
