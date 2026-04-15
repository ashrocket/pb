# Pastebot

## What it is
Pastebot is Tapbots’ macOS clipboard manager focused on quick recall, custom pasteboards, sequential paste queues, and filter-driven text transformations.

## Clipboard features
| Feature | Status | Notes |
| --- | --- | --- |
| History depth | configurable | Pastebot help says it stores the last 200 copied items by default and that this is editable in preferences. |
| Search | yes | Official help and marketing say it searches content and metadata, including app, date, and data type filters. |
| Image support | yes | Official clipboard docs describe compact and expanded image previews, and filters/help pages treat clippings as more than plain text. |
| Pinning | no direct pinning; permanent custom pasteboards instead | Pastebot’s durable-storage model is “custom pasteboards,” where clippings do not expire until manually deleted. |
| Snippets | reusable clippings/custom pasteboards, not text expansion | Pastebot supports permanent reusable clippings with per-clipping shortcuts, but the reviewed sources do not document a separate snippet/text-expansion system. |
| Sync | yes | Official site says the main clipboard, custom pasteboards, and filters sync across Macs through iCloud. |
| Hotkey | yes | Official Quick Paste help says the default quick-paste shortcut is `Command` + `Shift` + `V`; sequential paste defaults to `Control` + `Command` + `V`, and the queue window defaults to `Control` + `Command` + `C`. |

## Storage
- Path: not publicly documented in the reviewed sources
- Format: not publicly documented in the reviewed sources
- Encryption status: unknown from the reviewed public sources

## Security posture
- Concealed/transient handling: partially documented
- Pastebot help explicitly says Keychain and 1Password are blacklisted by default and that users can add more apps to the blacklist. The reviewed sources do not document exact pasteboard-type filtering.
- Password-manager exclusions: yes
- Official help names macOS Keychain and 1Password as default blacklist entries.
- Networked: yes
- Official site documents iCloud sync for clipboard/custom pasteboards/filters. I could not verify any additional network behavior, update framework, or telemetry posture from the reviewed public material.

## Performance claims
- Startup time: unknown
- Memory: unknown
- Sequential paste limit: official help says the queue window holds up to 25 items
- History size: official help documents 200 default clipboard items, editable in preferences
- DB size limits: not documented in reviewed public sources

## Known weaknesses
- I could not verify Pastebot’s local storage path, file format, or at-rest encryption details from public sources.
- This review is source-based only; Pastebot is a paid app and was not installed/runtime-tested here.
- Permanent storage is organized around custom pasteboards rather than generic pinning or full snippet/text-expansion features.
- Security blacklisting is documented at the app level, but the reviewed public help does not disclose the lower-level pasteboard-type filtering behavior.

## What I could and could not verify
- Verified from official site/help: 200-item default history, metadata search, image previews, filter chains, shell-script filters, custom pasteboards, sequential paste, default quick-paste and sequential-paste shortcuts, blacklist support, and iCloud sync.
- Verified from press coverage: long-standing reviews emphasize filters and folder/custom-pasteboard organization as the product’s main differentiators.
- Could not verify from public sources: local storage path, storage engine, exact on-disk encryption behavior, update/telemetry implementation details, or whether any hidden pasteboard-type exclusions exist beyond the documented app blacklist.

## Source
- https://tapbots.com/pastebot/
- https://tapbots.com/pastebot/help/
- https://tapbots.com/pastebot/help/01_getting_started/
- https://tapbots.com/pastebot/help/03_clipboard/
- https://tapbots.com/pastebot/help/04_custom_pasteboards/
- https://tapbots.com/pastebot/help/05_filters/
- https://tapbots.com/pastebot/help/06_quick_paste_menu/
- https://tapbots.com/pastebot/help/07_sequential_paste/
- https://tapbots.com/pastebot/help/08_preferences/
- https://www.wired.com/2011/12/pastebot-app
- https://www.lifewire.com/copy-paste-process-improvements-8647997
