# Clipy

## What it is
Clipy is a macOS clipboard extension app that combines clipboard history with
snippet folders.

## Clipboard features
| Feature | Status | Notes |
| --- | --- | --- |
| History depth | configurable | Reviewed source registers a default max history size of 30 and exposes `maxHistorySize` preferences that drive cleanup and menu construction. |
| Search | no documented search surface | The reviewed README and menu/history source show popup menus, folders, and numeric shortcuts, but no search field or documented type-to-search flow. |
| Image support | yes | Reviewed source stores TIFF clipboard images, generates thumbnails, and also handles PDF, filenames, and URL clipboard types. |
| Pinning | no | No pin/unpin feature was documented in the reviewed sources. |
| Snippets | yes | Clipy has snippet folders, snippet hotkeys, and a dedicated snippets editor window. |
| Sync | no | No sync feature was documented in the reviewed sources. |
| Hotkey | yes | Reviewed source defines default hotkeys for the main menu (`Command` + `Shift` + `V`), history menu (`Command` + `Control` + `V`), and snippets menu (`Command` + `Shift` + `B`). |

## Storage
- Path: partially documented; reviewed source explicitly writes archived clip
  payloads into `~/Library/Application Support/Clipy/`, but it uses Realm's
  default configuration for metadata so the exact Realm file path is not set in
  the reviewed sources.
- Format: Realm for metadata plus archived `.data` sidecar files and PINCache
  thumbnail objects
- Encryption status: unknown; no at-rest encryption was documented in the
  reviewed sources

## Security posture
- Concealed/transient handling: no explicit handling found
- The reviewed sources do not show checks for
  `org.nspasteboard.ConcealedType` or `org.nspasteboard.TransientType`.
- Password-manager exclusions: yes
- Reviewed source excludes 1Password-specific pasteboard types and supports a
  user-managed excluded-app list.
- Networked: yes at the app level
- Reviewed source wires Sparkle update checks to `https://clipy-app.com/appcast.xml`.

## Performance claims
- Startup time: unknown
- Memory: unknown
- Clipboard polling interval: reviewed source currently uses an Rx interval of
  `.microseconds(750)`; if interpreted literally, that is a very aggressive
  0.75 ms polling cadence
- History size: default 30, configurable through preferences
- DB size limits: no published database-size cap found in the reviewed sources

## Known weaknesses
- No search surface was documented in the reviewed sources, which leaves Clipy
  weaker than keyboard-search-driven tools.
- The reviewed sources do not show explicit concealed/transient clipboard
  filtering, so password hygiene appears more app-specific than type-based.
- Storage is split across Realm metadata, archived clip payload files, and
  thumbnail cache objects, which is more operationally complex than a single
  SQLite file.
- Clipy includes app-level networking through Sparkle update checks.

## Source
- https://github.com/Clipy/Clipy
- https://github.com/Clipy/Clipy/blob/develop/README.md
- https://github.com/Clipy/Clipy/blob/develop/Clipy/Sources/Constants.swift
- https://github.com/Clipy/Clipy/blob/develop/Clipy/Sources/Utility/CPYUtilities.swift
- https://github.com/Clipy/Clipy/blob/develop/Clipy/Sources/Services/ClipService.swift
- https://github.com/Clipy/Clipy/blob/develop/Clipy/Sources/Services/DataCleanService.swift
- https://github.com/Clipy/Clipy/blob/develop/Clipy/Sources/Services/ExcludeAppService.swift
- https://github.com/Clipy/Clipy/blob/develop/Clipy/Sources/Services/HotKeyService.swift
- https://github.com/Clipy/Clipy/blob/develop/Clipy/Sources/Managers/MenuManager.swift
- https://github.com/Clipy/Clipy/blob/develop/Clipy/Sources/Models/CPYClip.swift
- https://github.com/Clipy/Clipy/blob/develop/Clipy/Sources/Models/CPYClipData.swift
- https://github.com/Clipy/Clipy/blob/develop/Clipy/Sources/Extensions/Realm+Migration.swift
- https://github.com/Clipy/Clipy/blob/develop/Clipy/Sources/AppDelegate.swift
