# Raycast

## What it is
Raycast is a macOS productivity launcher whose built-in Clipboard History command stores and reuses recent clipboard items.

## Clipboard features
| Feature | Status | Notes |
| --- | --- | --- |
| History depth | time-based | Raycast says Clipboard History can be kept for up to 3 months. Exact item-count cap is unknown. |
| Search | yes | Current manual documents filtering/searching inside Clipboard History. |
| Image support | yes | Raycast documents images in Clipboard History. |
| Pinning | yes | Clipboard items can be pinned and kept indefinitely. |
| Snippets | yes | Raycast has a separate Snippets feature with personal and team-shared snippets. |
| Sync | limited | Clipboard History is intentionally not migrated by export and is not called out as cloud-synced; shared snippets exist only for teams. |
| Hotkey | yes | Clipboard History supports a custom alias or hotkey; a default dedicated hotkey was not documented. |

## Storage
- Path: unknown in reviewed sources
- Format: unknown in reviewed sources
- Encryption status: documented as encrypted local storage; Raycast says copied items stay on the Mac and are encrypted on the local hard drive

## Security posture
- Concealed/transient handling: effectively yes at the product level
- Password-manager exclusions: yes; Raycast says Clipboard History "respects your password manager" and ignores passwords and other transient data by default.
- Networked: yes at the app level; Raycast includes online extensions, accounts, and optional cloud/team features, but the Clipboard History feature page says copied content never leaves the computer.

## Performance claims
- Startup time: unknown
- Memory: no numeric memory figure found; Raycast claims Clipboard History is optimized for smooth performance with minimal impact on system resources
- Entry limit: text entries have a hard limit of 32,768 characters
- DB size limits: unknown

## Known weaknesses
- Clipboard History storage path and file format were not documented in the reviewed public sources.
- Clipboard History is not included in Raycast's Mac-to-Mac migration/export flow.
- Clipboard History and Snippets are separate systems, which means reusable text is split across two features instead of one store.

## Source
- https://manual.raycast.com/core
- https://www.raycast.com/core-features/clipboard-history
- https://manual.raycast.com/snippets
- https://manual.raycast.com/raycast-for-teams-beta/shared-snippets
- https://manual.raycast.com/mac/mac-mac-migration-guide
- https://www.raycast.com/faq
- https://www.raycast.com/changelog/macos/1-4-0
