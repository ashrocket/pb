# Threat Model

## Assets
- Clipboard text, URL, and image clips plus their timestamps and source bundle IDs
- The local SQLite history database at
  `~/Library/Application Support/clip-03/history.sqlite`
- The local runtime config file at
  `~/Library/Application Support/clip-03/config.toml`
- Global hotkey access to the history panel

## Adversaries
- Someone with access to the same logged-in macOS account
- Another same-user local process that can read files in the user account
- Operator mistakes, including copying secrets from apps that do not mark
  clipboard data as concealed or transient
- Oversized clipboard payloads that could bloat the store or UI

## What This Build Enforces
- Clipboard capture is local only. There is no network path, telemetry,
  updater, cloud sync, or remote API integration.
- Clipboard items carrying `org.nspasteboard.ConcealedType` or
  `org.nspasteboard.TransientType` are skipped before storage.
- The support directory is set to `0700`, the SQLite history file is set to
  `0600`, and startup re-validates the database permissions.
- Text and URL clips are stored as normalized UTF-8 strings. Image clips are
  re-encoded as PNG before storage.
- The config file is also kept at `0600`, and the UI settings window writes to
  that file instead of introducing a second settings store.
- Config reload is scoped to `config.toml` rather than the entire application
  support directory, so database writes do not trigger config reload churn.
- Query parsing is isolated in `QueryParser`, uses a fixed grammar, and the SQL
  layer uses prepared statements with bound parameters.
- Clipboard contents are not logged to stdout or to sidecar files.

## What This Build Does Not Enforce
- Encryption at rest is still not implemented. Anyone with access to the same
  user account can read the SQLite file directly.
- Sensitive plain text can still be captured if the source app does not mark
  the pasteboard as concealed or transient and is not added to the exclusion
  list.
- Secure deletion is not implemented. Deleted rows are removed logically from
  SQLite, but old page contents can remain until the database is vacuumed or
  deleted.
- The settings window validates only the supported flat config fields; invalid
  hand-edited TOML falls back to the last good parsed values instead of
  halting capture.
- The app does not defend against a malicious same-user process reading process
  memory, observing the pasteboard live, or opening files the user account can
  access.
