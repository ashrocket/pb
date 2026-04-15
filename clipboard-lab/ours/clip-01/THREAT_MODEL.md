# Threat Model

## Assets
- Clipboard history contents, especially copied text that may contain personal
  or business data.
- Captured images stored in clipboard history.
- Source application bundle identifiers attached to clipboard events.
- The local SQLite history database and its surrounding application support
  directory.
- The global hotkey path that can reveal clipboard history on demand.

## Adversaries
- A person with casual access to the same macOS account.
- Another local app running as the same user but without elevated privileges.
- An operator mistake, such as capturing password-manager or one-shot clipboard
  values into history.
- A local process that can read broad user files if the store is created with
  weak permissions.

## What This Build Enforces
- Clipboard capture uses polling only. It does not install event taps, network
  clients, update checks, or telemetry paths.
- Clipboard items tagged with `org.nspasteboard.ConcealedType` or
  `org.nspasteboard.TransientType` are skipped before storage.
- Runtime storage is scoped to the app support directory for this app and the
  code sets `0700` on the containing directory and `0600` on the SQLite file.
- The store is trimmed to the newest 200 entries to cap data retention.
- SQL writes and search queries use bound parameters, which avoids raw string
  interpolation for user-entered search terms.
- Clipboard contents are not printed to stdout or written to ad hoc logs.

## What This Build Does Not Enforce
- Encryption at rest is not implemented. This keeps iter 1 simple and avoids
  key-management decisions, but the database remains readable to anyone with
  access to the same user account.
- Protection from malicious local processes is not provided. A process running
  as the same user can still inspect the app's files or process memory.
- Concurrent multi-process access to the same SQLite file is not coordinated.
  The app assumes a single local writer.
- Rich-type filtering is intentionally narrow. Only concealed and transient
  pasteboard hints are excluded, so sensitive plain text copied from ordinary
  apps can still be captured.
- Secure deletion is not attempted. Deleted rows are trimmed from SQLite, but
  old bytes may persist until the database is vacuumed or the file is removed.
- The app does not authenticate who triggered the history window. Anyone using
  the logged-in session can invoke the hotkey or click the status item.
