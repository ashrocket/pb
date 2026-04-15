# clip-04

`clip-04` is a menu bar clipboard history manager for macOS built with SwiftPM,
AppKit, Carbon hotkeys, CryptoKit, Security.framework, and raw `sqlite3`.

## What Changed In Iter 4
- Clip payloads are encrypted before `INSERT` and decrypted after `SELECT`.
- The encryption key is derived from random passphrase material stored in the
  macOS Keychain.
- Settings now cover history retention count, polling interval, hotkey modifier
  choice, excluded apps, pause capture, max clip size, and auto-start at login.
- URL detection now uses `NSDataDetector` instead of the `URL(string:)`
  heuristic from `clip-03`.
- Query parsing now supports `encrypted:yes|no`.

## Features
- Menu bar app with `LSUIElement` enabled
- Global hotkey on `V` with configurable modifier presets
- Plain-text and image clipboard capture
- Plain-text URL classification through `NSDataDetector(.link)`
- Search grammar:
  - free text terms
  - quoted phrases
  - `type:text|image|url`
  - `app:<bundleid>`
  - `after:<iso-date>`
  - `encrypted:yes|no`
  - `image:` alias
- Persistent SQLite history store at
  `~/Library/Application Support/clip-04/history.sqlite`
- `0600` permissions on the history file
- Concealed/transient pasteboard exclusion

## Build
```bash
./scripts/build.sh
```

## Test
This environment still lacks `XCTest`, so the package uses a framework-free
SwiftPM test target with explicit assertions.

```bash
CLANG_MODULE_CACHE_PATH="$PWD/.build/module-cache" \
SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache" \
SWIFTPM_CUSTOM_CACHE_PATH="$PWD/.build/local-cache" \
XDG_CACHE_HOME="$PWD/.build/local-cache" \
swift test --disable-sandbox
```

## Limits
- Search still relies on a plaintext `searchable_text` index, so encrypted
  payloads do not imply a fully opaque database.
- Auto-start at login is best-effort through `SMAppService.mainApp`.
- The hotkey setting changes modifiers only; the key itself remains `V`.
