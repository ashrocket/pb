# Self Review

## Verdict
`clip-04` meets the iter-4 mandate. It keeps the `clip-03` structure but adds
encrypted payload storage, broader in-app settings, `NSDataDetector` URL
classification, and wider test coverage.

## What Improved
- Payloads are now encrypted at rest, with key material sourced from the macOS
  Keychain instead of the SQLite file.
- The settings window is now broad enough to manage retention count, polling
  interval, hotkey modifier presets, excluded apps, and login-item behavior.
- URL detection is materially better than `clip-03`'s `URL(string:)` heuristic
  because classification is now driven by `NSDataDetector(.link)`.
- The query DSL kept the useful iter-3 grammar and added `encrypted:yes|no`.
- Test coverage now explicitly exercises encryption round-trip, URL detection
  edge cases, and the parser.

## Remaining Weaknesses
- `searchable_text` remains plaintext so substring search still leaks clip
  content into the database index.
- Key rotation is documented but not implemented. If the Keychain material is
  lost, existing ciphertext becomes unreadable.
- Auto-start at login is best-effort through `SMAppService.mainApp`; the UI
  does not surface OS-level registration failures.
- The settings UI is broader, but excluded-app editing is still raw bundle-ID
  text rather than a friendlier picker.
- The test target is still framework-free because this toolchain image does not
  ship `XCTest`.

## Release Readiness
- Build/package flow: ready
- At-rest payload protection: meaningfully improved
- Full production secrecy claim: not yet justified because metadata and search
  index remain plaintext
