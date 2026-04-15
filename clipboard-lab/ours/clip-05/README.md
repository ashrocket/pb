# clip-05

`clip-05` is a local-first macOS clipboard history app built with AppKit,
SwiftPM, raw `sqlite3`, `CryptoKit`, `Security.framework`, and `Vision`.
It is the final iteration in this lab and is optimized for blind-review polish:
encrypted storage, encrypted token-prefix search, OCR-backed image search,
visual previews, and a cleaner performance profile than the earlier builds.

## Features
- Menu bar app with a keyboard-driven history panel
- Global hotkey on `V` with configurable modifier presets
- Plain-text, URL, and image capture
- `NSDataDetector` URL classification for standalone links
- On-device OCR for image clips through `Vision`
- Encrypted payload storage using Keychain-backed keys
- Encrypted token-prefix search index for text and OCR metadata
- Lazy-loaded history list with image thumbnails and preview pane
- Debounced search and background image decoding
- Local config file and settings window
- No telemetry, no sync, and no intentional network traffic

## Install
Build the unsigned app bundle:

```bash
./scripts/build.sh
```

The script writes:

```text
build/clip-05.app
```

Because the bundle is unsigned, macOS may block the first launch. If needed,
remove the quarantine attribute and open it directly:

```bash
xattr -dr com.apple.quarantine build/clip-05.app
open build/clip-05.app
```

The app stores data at:

```text
~/Library/Application Support/clip-05/history.sqlite
~/Library/Application Support/clip-05/config.toml
```

## Search Grammar
Supported query forms:

- free terms: `invoice portal`
- quoted phrases: `"prior auth"`
- type filter: `type:text`, `type:image`, `type:url`
- image alias: `image:receipt`
- source app filter: `app:com.apple.Safari`
- time filter: `after:2026-04-01` or full ISO-8601 timestamps
- encryption filter: `encrypted:yes` or `encrypted:no`

Terms are normalized, tokenized, and matched by encrypted token prefix.
That means:

- `port` matches `portal`
- `auth` matches `authorization`
- `rtal` does not match `portal`
- infix substring search is intentionally not supported

This trade-off removes the earlier plaintext searchable-text leak from the
database at the cost of weaker free-form substring matching.

## Settings Reference
The settings window and `config.toml` expose:

- `auto_start_at_login`
- `pause_capture`
- `history_retention_count`
- `max_bytes_per_clip`
- `polling_interval_seconds`
- `hotkey_modifiers`
- `excluded_bundle_ids`

Notes:

- Polling values below `0.10` seconds are clamped.
- The hotkey always uses the `V` key; settings change only modifier sets.
- Excluded apps are matched by bundle identifier.
- `pause_capture` stops new clipboard ingestion without deleting history.

## Security Posture
- Clip payloads are encrypted before insertion into SQLite.
- OCR text is encrypted before storage and indexed only through HMAC hashes.
- The primary key material lives in the macOS Keychain, not in the database.
- The app support directory is forced to `0700`; the SQLite file is forced to
  `0600`.
- Concealed and transient pasteboard types are skipped.
- The app is local-only by design and does not send clipboard contents over the
  network.

See [THREAT_MODEL.md](THREAT_MODEL.md) for the full model and explicit limits.

## Performance Notes
- The history panel loads 20 clips at a time and fetches more on scroll.
- Search is debounced by 200 ms.
- Thumbnails and image previews decode off the main thread.
- OCR service and settings-window setup are deferred until after the menu bar
  item is live.

## Testing
This environment does not provide a usable `XCTest` runtime, so verification is
split in two parts:

1. `swift test --disable-sandbox`
   - compile gate for the package and test target
2. standalone verifier under `Tests/Verifier/main.swift`
   - executes the real case suite

The verifier currently covers more than 20 cases, including:

- encryption round-trip
- encrypted token-prefix search behavior
- query parsing
- URL detection edge cases
- OCR metadata flow with a generated PNG
- config watcher reload behavior

## Known Limitations
- Search is prefix-based rather than arbitrary substring search.
- Decrypted clip payloads necessarily exist in process memory while the UI is
  showing or re-copying them.
- OCR is asynchronous, so a newly captured image may appear before its text is
  searchable.
- Login-item registration uses `SMAppService.mainApp` on a best-effort basis.
- There is no key rotation or migration tool in this iteration.
