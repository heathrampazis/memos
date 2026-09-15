# Memos

An iOS note-taking app. Memos are sticky notes on a board — text, checklists,
photos, drawings and audio, organised into colour-coded folders.

## Requirements

- Xcode 16 or later
- iOS 17 or later (SwiftData)
- No third-party dependencies

## Running

Open `Memos.xcodeproj` and run the `Memos` scheme. There is no setup step.

## Project structure

Code is organised by responsibility rather than by type. Folders are added as
the work reaches them.

| Folder | Holds |
|---|---|
| `App/` | Entry point and root navigation |
| `Design/` | Palette, theme, typography, spacing, icons. No app logic |
| `Models/` | `Memo`, `Folder`, `Block` |
| `Storage/` | `MemoStore` — the only code that touches persistence |
| `Components/` | Reusable views that take plain values, never model types |
| `Features/` | One folder per screen area: Board, Editor, Folders, Search, Settings |
| `Resources/` | Fonts and asset catalogue |

### The rule that keeps it modular

**Components must not know about the data model.** `StickyCard` takes a colour,
an icon, a title and a subtitle — not a `Memo`. The card appears on the board,
in search results, in the widget, in folder previews and in settings; if it took
a `Memo`, every one of those would need to fabricate one just to render, and so
would every SwiftUI preview.

Features own screens. Components own the pieces screens share. When a view is
used by two features, it moves to `Components/`.

## Conventions

- Colours come from `Theme`, sizes from `Spacing`, fonts from `Typography`.
  No literals at call sites.
- Comment *why*, not *what*. No file header blocks, no section dividers.
- Every new view has a `#Preview`.
- One issue, one branch, one pull request. `main` always builds.

Branches are named after the ticket: `m0-1/repo-setup`, `m1-3/masonry-layout`.

## Roadmap

| Milestone | Scope |
|---|---|
| M0 | Foundation — design system and `StickyCard` |
| M1 | Board, running on sample data |
| M2 | Persistence with SwiftData |
| M3 | Text editor and the formatting tray |
| M4 | Media blocks — photo, camera, audio, drawing |
| M5 | Block selection and image sizing |
| M6 | Folders, search, appearance settings |
| M7 | Widget, haptics, app icon, accessibility |
