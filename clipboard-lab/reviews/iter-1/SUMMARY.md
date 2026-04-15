# Iteration 1 Summary

- Install step ran for both `maccy` and `raycast`, but neither installed.
- Failure cause was local Homebrew permissions, not missing casks:
  - `/opt/homebrew` and `/opt/homebrew/Cellar` not writable
  - `~/Library/Caches/Homebrew` and `~/Library/Logs/Homebrew` not writable
- Because the apps are not present locally, launch smoke tests were skipped for both.
- No successful `open -a` / `pgrep -f` verification happened in this run.
- Maccy review: local-first, open source, SQLite-backed at `~/Library/Application Support/Maccy/Storage.sqlite`, explicit concealed/transient pasteboard exclusion, no documented sync/snippets.
- Raycast review: clipboard history is encrypted locally, time-retained up to 3 months, pinning/search/images supported, but storage path/format are not documented in the reviewed public docs.
- Common finding: both products emphasize privacy by filtering sensitive clipboard content and keeping clipboard history local.
- Key difference: Maccy is a focused clipboard utility; Raycast is a broader networked launcher platform with clipboard history as one built-in feature and snippets as a separate system.
- `clip-01` direction: build a narrow, native menu bar clipboard manager with a 200-entry SQLite store, substring search, image support, and a single global hotkey.
- The design deliberately avoids sync, snippets, rich text complexity, and extra dependencies in iter 1.
- User action needed before iter 2:
  - fix local Homebrew ownership/permissions so `brew install --cask maccy` and `brew install --cask raycast` can succeed
  - after install, grant Accessibility and Input Monitoring so runtime interaction testing can happen
