Added `existing/flycut.md` from Flycut upstream sources, covering its
Jumpcut lineage, plist/NSUserDefaults storage, text-only bias, optional
iCloud sync, default 40-item history, default `Shift + Command + V` hotkey,
and concealed/transient skip list.
Built a new SwiftPM package at `ours/clip-04/`.
`clip-04` adds `Encryption.swift` with Keychain-backed key material and
`AES.GCM` payload encryption before `INSERT` plus decryption after `SELECT`.
`THREAT_MODEL.md` now documents key creation, storage, derivation, rotation
limits, and the key-loss scenario explicitly.
`SettingsWindow.swift` now covers retention count, polling interval, hotkey
modifier presets, excluded apps, pause capture, max clip size, and
auto-start-at-login.
`URLDetector.swift` replaces the old heuristic with `NSDataDetector(.link)`.
`QueryParser.swift` carries forward the iter-3 grammar and adds
`encrypted:yes|no`.
The framework-free SwiftPM harness now covers encryption round-trip, URL
detection edge cases, and query parsing.
Build output app bundle:
`/Users/ashleyraiteri/ashcode/agent-pb/clipboard-lab/ours/clip-04/build/clip-04.app`
Build/test log: `reviews/iter-4/clip-04-build.log`
Build status: pass.
Test status: pass with `swift test --disable-sandbox` plus local cache env
overrides.
Validation fixes: build script execute bit, SwiftPM module-cache override for
tests, and missing `Foundation` import in the harness.
Self-review, simplify log, and team review are written under
`reviews/iter-4/`.
Main remaining risk: payloads are encrypted, but `searchable_text` stays
plaintext to preserve substring search.
