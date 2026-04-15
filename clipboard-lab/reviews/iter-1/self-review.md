# Self Review

## Bugs I Can See In My Own Code
- The current source does not compile cleanly under Swift 6.2. The build log shows actor-isolation violations around AppKit access and missing `SQLITE_TRANSIENT` bindings in the SQLite layer.
- The build script needed environment-specific cache overrides and `--disable-sandbox` before SwiftPM would even evaluate the manifest in this workspace. That is operationally brittle.
- The history panel depends on double-click to replay an item, which is weak for keyboard-driven use and easy to miss.
- The poller captures only the first pasteboard item. Multi-item clipboard contents are dropped silently.
- Image replay writes an `NSImage` back to the pasteboard but does not preserve the original representation or ancillary metadata.

## Missing Features From The Design Brief
- The popup does not yet provide a clearly lightweight image preview beyond a thumbnail in each row. There is no dedicated preview state.
- Search is substring-only over `searchable_text`, but image records are barely searchable because their metadata is just source bundle id plus the literal word `image`.
- The design implies an AppKit popup feel tied to the menu bar. The current positioning logic is hand-rolled and may still feel like a generic floating window.

## Security Holes
- Excluding concealed and transient types is necessary but nowhere near sufficient to avoid sensitive capture. Ordinary copied passwords from apps that do not mark those types will still be stored.
- Clipboard history is plaintext at rest in SQLite. A local user or process with access to the account can read it directly.
- The app trusts the frontmost app bundle id at polling time, which is best-effort metadata and can be misleading when focus changes quickly.

## Performance Concerns
- The panel reloads and re-queries the database on every new capture and every search-field edit. At 200 rows this is acceptable, but the update path is still noisier than it needs to be.
- Images are stored as TIFF blobs in SQLite. That is simple, but it can bloat the database quickly compared with a compressed representation.
- Deduplication compares the newest record payload directly in Swift. That is fine at this scale, but it would get expensive if the retention cap grows.

## What I'd Change With More Time
- Fix the Swift 6 concurrency surface cleanly instead of leaving AppKit usage sprinkled through nonisolated types.
- Add explicit keyboard handling: arrow navigation from the search field, Return to copy, Escape to dismiss.
- Make image handling smarter by generating small previews for the list while storing a space-efficient representation.
- Add a pause/disable capture mode and clearer first-run guidance about what the app records and what it intentionally does not protect.
