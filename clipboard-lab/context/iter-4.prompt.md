# Codex dispatch: iter-4 — Flycut review + build clip-04 + reviews

READ `clipboard-lab/CONTEXT.md`, `clipboard-lab/SPEC.md`,
`clipboard-lab/reviews/iter-3/build-SUMMARY.md`,
`clipboard-lab/reviews/iter-3/team-review.md`,
and skim the clip-03 source tree BEFORE ANY WORK.

## Mandate
1. Add Flycut to the existing-review set.
2. Build clip-04 addressing iter-3 weaknesses:
   - **Encrypted-at-rest storage**: use SQLCipher-compatible approach OR
     CommonCrypto/CryptoKit to encrypt clip payloads before INSERT and
     decrypt on SELECT. Key derived from a passphrase stored in the macOS
     Keychain via Security.framework. Document the key management in
     THREAT_MODEL.md.
   - **Broader settings window**: add controls for history retention count,
     polling interval, hotkey customization (at least modifier choice),
     per-app exclusion editing, and auto-start-at-login toggle.
   - **Improved URL detection**: use `NSDataDetector` with `.link` type
     to detect URLs in plain-text clips and tag them as `url` kind,
     replacing the heuristic from clip-03.
   - **Test framework**: build a real XCTest target if possible, or
     continue the framework-free harness from clip-03 with explicit
     assertions. Cover encryption round-trip, URL detection edge cases,
     and query parser from clip-03 (include that parser in clip-04).
3. Self-review, simplify, team-review, summarize.

## Step 1. Flycut review
Write `existing/flycut.md`. Flycut is an open-source Jumpcut fork
(https://github.com/TermiT/Flycut). Note: it uses a plist store, very
minimal, text-only. Cite sources.

## Step 2. Build clip-04
New package at `ours/clip-04/`. Same hard rules: no Xcode, no SPM deps
beyond what ships with macOS SDK, LSUIElement, concealed/transient
exclusion, no network (except Keychain access), 0600 file perms.

Key source files to create:
- `Sources/clip-04/Encryption.swift` — encrypt/decrypt payloads, keychain
  key management
- `Sources/clip-04/SettingsWindow.swift` — expanded settings
- `Sources/clip-04/URLDetector.swift` — NSDataDetector-based
- `Sources/clip-04/QueryParser.swift` — carried over + improved from
  clip-03, add `encrypted:yes|no` filter
- Standard files: main.swift, MenuBar.swift, ClipboardPoller.swift,
  Store.swift, HotkeyManager.swift, HistoryWindow.swift,
  ClipConfiguration.swift

Run `scripts/build.sh`. Retry up to 3 times. Run tests with
`swift test --disable-sandbox` if needed. Log everything to
`reviews/iter-4/clip-04-build.log`.

Write `ours/clip-04/THREAT_MODEL.md` — must explicitly cover the key
management lifecycle (creation, storage, rotation, loss scenario).

## Step 3. Self-review, simplify, team review
- `reviews/iter-4/self-review.md`
- `reviews/iter-4/simplify-log.md`
- `reviews/iter-4/team-review.md` (4 personas, compare against Maccy,
  Raycast, Alfred, Clipy, Flycut — the full existing set now)

## Step 4. Summary
`reviews/iter-4/build-SUMMARY.md` (≤30 lines).

## Step 5. Done
Write `DONE` to `reviews/iter-4/iter.done`.
