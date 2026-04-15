# Alfred

## What it is
Alfred is a macOS productivity launcher. Its clipboard history is not part of
the free tier: Clipboard History is a Powerpack feature, so a base/free Alfred
install does **not** include clipboard history until a Powerpack license is
activated.

## Clipboard features
| Feature | Status | Notes |
| --- | --- | --- |
| History depth | time-based | Powerpack Clipboard History can retain clips for 24 hours, 7 days, 1 month, or 3 months. Free-tier Alfred has no clipboard history at all. |
| Search | yes | Powerpack Clipboard History is searchable by typing words or phrases from the original clip. |
| Image support | yes | Alfred documents Clipboard History for text, images, and file links. |
| Pinning | no | Current reviewed docs describe clearing, searching, merging, and saving clips as snippets, but not pinning clipboard items in history. |
| Snippets | yes | Snippets and text expansion are Powerpack features, and text clips can be promoted from Clipboard History into Snippets with `Cmd + S`. |
| Sync | limited | Alfred can sync preferences, workflows, snippets, and themes between Macs, but the official sync guide explicitly excludes Clipboard History enabled state and history data from sync. |
| Hotkey | yes | Clipboard History uses a customisable viewer hotkey, but the current help pages do not document a fixed default shortcut. |

## Storage
- Path: partially documented; Alfred's default local preferences live under `~/Library/Application Support/Alfred/`, and the clipboard troubleshooting guide says clearing history rebuilds `clipboard.db`. The official docs do not publish the exact current subpath of that database, so the precise clipboard DB location is best treated as undocumented.
- Format: database (`clipboard.db`); engine not documented in current official help
- Encryption status: unknown in reviewed sources

## Security posture
- Concealed/transient handling: yes, with caveat
- Clipboard History is disabled by default for privacy, Alfred ignores popular password apps by default, and the Clipboard feature page says it ignores concealed clipboard data by default unless the user opts in to store it.
- Password-manager exclusions: yes
- Official help explicitly calls out ignored apps such as Keychain Access and 1Password, and supports adding more ignored apps manually.
- Networked: yes at the app level
- Alfred can sync preferences between Macs and includes broader launcher/workflow features, but current docs do not claim clipboard contents themselves are networked. Clipboard history data is specifically excluded from Alfred's preferences sync.

## Performance claims
- Startup time: unknown
- Memory: unknown
- Clipboard retention cap: time-based retention up to 3 months
- Max clip size: configurable for text; Alfred says you can set a maximum clip size so very large copied text is ignored
- DB size limits: no published numeric database-size claim found; troubleshooting only describes a "small database" rebuilt as `clipboard.db`

## Known weaknesses
- Free-tier Alfred does not provide clipboard history at all; the comparison only becomes relevant once Powerpack is activated.
- Clipboard History requires Accessibility permission for some actions, including clipboard pasting behavior.
- Clipboard History does not sync between Macs even when Alfred preferences syncing is enabled.
- Current official docs do not clearly document the exact on-disk clipboard database path, storage engine, encryption-at-rest behavior, or a default Clipboard History hotkey.

## Source
- https://www.alfredapp.com/help/why-choose-alfred/
- https://www.alfredapp.com/powerpack/
- https://www.alfredapp.com/help/features/clipboard/
- https://www.alfredapp.com/help/troubleshooting/clipboard-history/
- https://www.alfredapp.com/help/features/snippets/
- https://www.alfredapp.com/help/features/snippets/editing-snippets/
- https://www.alfredapp.com/help/advanced/sync/
- https://www.alfredapp.com/help/advanced/sync/disable-sync/
