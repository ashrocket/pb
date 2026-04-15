# clip-01 Design Brief

## Goal
`clip-01` is a Swift 6.2 macOS menu bar clipboard manager built with Swift Package Manager and bundled by hand as an unsigned `.app`, with no Xcode dependency.

## Iteration 1 scope
- Menu bar app with an AppKit popup window
- Global hotkey: `Command` + `Shift` + `V`
- Clipboard history target: 200 entries
- Persistent store: SQLite at `~/Library/Application Support/clip-01/history.sqlite`
- Search: substring match over stored plain text metadata
- Content support: plain text plus images
- Security baseline: skip `org.nspasteboard.ConcealedType` and `org.nspasteboard.TransientType`; no network, telemetry, or update checks

## Operating model
- Clipboard capture will use pasteboard polling rather than event taps.
- The app will normalize each accepted clipboard item into a compact record with:
  - stable id
  - capture timestamp
  - source app bundle id when available
  - content kind (`text` or `image`)
  - searchable text field
  - binary payload for images
- The popup will present newest-first history, a search field, and lightweight previews.
- The store file must be created with `0600` permissions.

## Explicit non-goals for iter 1
- Cloud sync
- Snippets or text-expander behavior
- Rich-text preservation beyond plain text plus image capture
- Multi-device behavior of any kind

## Decisions made
1. Use raw `sqlite3` instead of GRDB.
Reason: iter 1 is intentionally small, and removing a package dependency keeps the SPM build and hand-bundled app simpler to reason about.

2. Store images inside SQLite rather than as sidecar files.
Reason: at a 200-entry target, atomic writes and one-file persistence are more valuable than optimizing for very large media libraries.

3. Use substring search over normalized plain-text metadata, not fuzzy ranking.
Reason: substring search is predictable, easy to test from the CLI, and good enough for a 200-entry local history without adding ranking complexity in the first build.

## Consequences
- `clip-01` should feel closer to Maccy's focused local model than to Raycast's broader launcher platform.
- The first implementation should optimize for correctness, deterministic storage, and low moving parts rather than feature breadth.
- If the 200-entry image payload makes the single SQLite file too heavy, iter 2 can revisit image storage after measuring the real footprint.
