# Self Review

## Bugs I Can See In My Own Code
- The config watcher now reloads the TOML file on any FSEvents activity inside
  the app support directory. That keeps the callback simple, but it also means
  database writes can trigger unnecessary config parses.
- The app still captures only the first pasteboard item. Multi-item clipboard
  payloads are silently ignored.
- Config parse failures keep the last good configuration without any user-facing
  error state. That is safer than crashing, but it can make bad edits hard to
  diagnose.
- The quick-pick shortcuts are limited to the first nine visible rows. There is
  no paging or richer jump model.

## Missing Features From The Iter-2 Direction
- The README documents keyboard controls, but there is still no settings UI for
  editing ignored apps, max size, or pause state. All privacy tuning lives in
  the config file.
- `image:` filtering works, but image search is still metadata-only. There is
  no OCR or semantic search for screenshots.
- The panel is positioned near the top center of the screen rather than being
  anchored directly to the menu bar item.

## Security Holes
- Clipboard history remains plaintext at rest in SQLite. Same-user access still
  means full history access.
- Per-app exclusions help, but sensitive plain text from ordinary apps can
  still be captured if the source does not mark the pasteboard as concealed or
  transient.
- Secure deletion is still not implemented, so trimmed rows can leave data in
  old SQLite pages until the database is vacuumed or removed.
- Source application bundle IDs are stored for usability and filtering, which
  also creates a behavioral history trail.

## Performance Concerns
- PNG is a real improvement over TIFF for screenshots, but storing full image
  blobs in SQLite is still a growth risk if the history cap increases or users
  copy many large screenshots under the 1 MB limit.
- Search still re-queries SQLite on every edit. At 200 rows this is fine, but
  it does not scale as gracefully as a cached index would.
- Thumbnails decode lazily from PNG data during row rendering. That keeps
  startup light, but scrolling can still cause bursty decode work.

## What I'd Change With More Time
- Add a small settings window or menu-driven controls for pause capture,
  ignored apps, history clearing, and byte-cap changes.
- Tighten the FSEvents watcher so config reload only happens for config file
  changes and not for SQLite churn in the same directory.
- Add secure maintenance operations such as clear-all, optional source-app
  storage disablement, and periodic `VACUUM`.
- Improve power-user search with more prefixes beyond `image:` and better
  non-text discovery.
