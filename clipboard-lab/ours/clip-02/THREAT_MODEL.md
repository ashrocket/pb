# Threat Model

## Assets
- Clipboard text clips, image clips, and the metadata attached to them
- Source application bundle identifiers used for per-app exclusion
- The local SQLite history database and the watched TOML config file
- The global hotkey path used to reveal clipboard history

## Adversaries
- Someone with access to the same logged-in macOS account
- Another local process running as the same user
- Operator mistakes, such as copying secrets from apps that do not mark the
  pasteboard as concealed or transient
- Oversized clipboard payloads that could bloat the local store

## What This Build Enforces
- Clipboard capture is local only. It does not include network paths,
  telemetry, update checks, or cloud sync.
- Clipboard items carrying `org.nspasteboard.ConcealedType` or
  `org.nspasteboard.TransientType` are skipped before storage.
- Runtime state lives under `~/Library/Application Support/clip-02/`.
  The support directory is set to `0700`, the SQLite file is set to `0600`,
  and startup re-validates the database permissions.
- Images are re-encoded as PNG before storage, and each row stores width,
  height, and byte count metadata for more predictable search and display.
- The config file applies three privacy controls: pause capture, per-app bundle
  exclusion, and a max-bytes-per-clip cap with a default of 1 MB.
- Config changes are applied on launch and while the app is running through an
  FSEvents watcher on the app support directory.
- SQL reads and writes use prepared statements and bound parameters.
- Clipboard contents are not logged to stdout or to sidecar files.

## What This Build Does Not Enforce
- Encryption at rest is still not implemented. Anyone with access to the same
  user account can read the SQLite file directly.
- Sensitive plain text copied from ordinary apps can still be captured if the
  source app does not mark the pasteboard as concealed or transient and is not
  excluded in the config file.
- Secure deletion is not implemented. Deleted rows are removed logically from
  SQLite, but old page contents can persist until the database is vacuumed or
  deleted.
- The config parser intentionally supports only the three documented flat keys.
  Invalid TOML keeps the last good configuration instead of failing closed.
- The app does not protect against a malicious same-user process reading
  process memory, the support directory, or the active clipboard.
