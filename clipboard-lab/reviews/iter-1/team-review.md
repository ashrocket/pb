# Team Review

## Security reviewer
- The concealed and transient pasteboard exclusions are correctly enforced, but the app still captures any plain text that is not explicitly marked sensitive. Add an optional pause mode or per-app denylist in iter 2.
- The SQLite file permissions are set in code, which is good, but there is no verification step after open. Re-check mode bits after initialization and fail closed if they drift.
- Clipboard data is stored unencrypted at rest. That is acceptable for iter 1 only if the threat model stays explicit about same-user compromise.
- The app does not scrub deleted content from SQLite pages. If retention is supposed to be meaningful for privacy, add a periodic `VACUUM` or move to sidecar files with secure deletion semantics.
- Source app bundle ids are recorded as metadata. That helps UX, but it also leaks behavior history. Consider making source tracking optional.

## UX reviewer
- `Command` + `Shift` + `V` is a reasonable default hotkey, but there is no settings UI to change it if it conflicts with another app.
- The window now opens centered, which is simpler but less menu-bar-native. Bring it back toward the status item in iter 2 if you can do it without brittle geometry code.
- Search feels straightforward because it is literal substring matching, but images are almost impossible to discover by search. Add better image labels or OCR later.
- The row design is readable, but the replay action is still under-discoverable. Make Return copy the current row and show a short hint in the panel.
- First-run experience is weak. There is no explanation of what gets captured, what is excluded, or where the data lives.

## Performance reviewer
- Polling at a fixed interval is acceptable for a 200-entry target, but it still wakes the app continuously. Measure the idle cost before increasing scope.
- Keeping only 200 rows caps query cost nicely. That is the biggest performance-friendly decision in the build.
- Storing TIFF blobs in SQLite is the main footprint risk. A few large screenshots will inflate the database faster than expected.
- Re-querying SQLite on each search-field edit is fine at this size, but an in-memory cache would make the UI more predictable if the history cap grows.
- Startup should stay fast because the app does not eagerly decode all records, but image thumbnails in the table will still create bursty decode work during scrolling.

## Power user reviewer
- The app has the right local-history core, but it is missing the features power users expect most: pinning, favorites, snippets, and custom hotkeys.
- Search is too basic for daily heavy use. Add prefix filters, regex or fuzzy search, and better metadata handling for non-text entries.
- There is no way to act on more than one history at a time, no paste-stack behavior, and no multi-clipboard concept by app or workspace.
- The database limit is sensible, but there is no UI for retention control or history clearing.
- Status-item plus hotkey is enough for iter 1. Anything beyond that, like sync or automation hooks, would be extraneous before keyboard flow and search quality improve.
