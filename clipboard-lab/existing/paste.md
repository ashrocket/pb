# Paste

## What it is
Paste is a polished clipboard manager for Mac, iPhone, and iPad with a visual history UI, cross-device iCloud sync, and long-lived Pinboards for saved clippings.

## Clipboard features
| Feature | Status | Notes |
| --- | --- | --- |
| History depth | configurable/time-based | Paste’s Mac onboarding says you choose how much clipboard history it keeps, but the reviewed public materials do not publish a numeric default or hard cap. |
| Search | yes | Official help documents search plus filters by app, time, device, and content type, and says Paste can search inside images. |
| Image support | yes | Official materials repeatedly describe text, links, images, and files with previews and image-aware search. |
| Pinning | yes | Pinboards are Paste’s primary long-lived “pin/save” mechanism; pinned items do not expire with normal clipboard history. |
| Snippets | yes-ish | Paste does not market a separate text-expansion/snippets product, but Pinboards are clearly positioned for reusable text, code, and templates. |
| Sync | yes | Official docs say clipboard history and Pinboards sync via private iCloud across Mac, iPhone, and iPad; shared Pinboards also use Apple iCloud sharing. |
| Hotkey | yes | Official keyboard shortcuts page lists the default show/hide shortcut as `Shift` + `Command` + `V`. |

## Storage
- Path: not publicly documented in the reviewed sources
- Format: not publicly documented in the reviewed sources
- Encryption status: partially documented; Paste says data is stored locally and, when sync is enabled, in the user’s private iCloud account, but the reviewed public sources do not describe on-disk file format or Mac at-rest encryption implementation details

## Security posture
- Concealed/transient handling: partially documented
- Official Mac help says users can ignore confidential content, exclude specific apps such as password managers, and pause capture, but the public sources reviewed did not expose the exact pasteboard-type skip list.
- Password-manager exclusions: yes
- Official Mac help and marketing pages say Paste can exclude apps with sensitive data like password managers from capture.
- Networked: yes, but narrowly described
- Official materials say data stays local and in the user’s private iCloud when sync is enabled, and shared Pinboards use Apple’s native iCloud sharing. I could not verify additional app-level networking behavior such as update delivery from the reviewed public material.

## Performance claims
- Startup time: unknown
- Memory: unknown
- Search/UX claim: official materials emphasize a visual history, quick keyboard recall, and image-text search, but publish no numeric performance benchmarks
- History-size limits: not documented in reviewed public sources
- DB size limits: not documented in reviewed public sources

## Known weaknesses
- I could not verify the Mac storage path, database format, or exact encryption-at-rest implementation from public sources.
- Paste is subscription/lifetime-purchase software, so this review is source-based only; I did not install or runtime-test it here.
- Pinboards appear to cover many “snippet” use cases, but the reviewed public sources do not document a separate text-expansion engine comparable to Alfred Snippets.
- Search is feature-rich, but the reviewed public docs do not specify whether very large histories have hard count limits or only retention-policy limits.

## What I could and could not verify
- Verified from official docs/site/App Store: visual history, image support, search filters, image-text search, Pinboards, shared Pinboards, iCloud sync, default shortcut, privacy controls, and pause mode.
- Verified from press coverage: reviewers describe Paste as visually oriented and preview-heavy rather than purely text-list based.
- Could not verify from public sources: local storage path, file/database engine, exact at-rest encryption details, hidden pasteboard-type exclusions, or hard history/database ceilings.

## Source
- https://pasteapp.io/
- https://pasteapp.io/mac
- https://pasteapp.io/help/explore-paste
- https://pasteapp.io/help/paste-on-mac
- https://pasteapp.io/help/search-and-filters
- https://pasteapp.io/help/organize-with-pinboards
- https://pasteapp.io/help/shared-pinboards
- https://pasteapp.io/help/keyboard-shortcuts
- https://apps.apple.com/us/app/paste-limitless-clipboard/id967805235
- https://www.macworld.com/article/804417/paste-review.html
- https://9to5mac.com/2015/07/03/mac-clipboard-manager-reviews-paste/
