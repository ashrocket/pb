Added `existing/clipy.md` using the same field structure as `existing/maccy.md`, with GitHub source citations covering Realm metadata, sidecar clip payloads, snippets, hotkeys, update networking, and the default history-size settings.
Built a new SwiftPM package at `ours/clip-03/` without touching `clip-01` or `clip-02`.
`clip-03` adds a real AppKit settings window in `Sources/clip-03/SettingsWindow.swift`.
The config watcher now targets only `config.toml` and filters event paths before reload.
Search is now handled by `Sources/clip-03/QueryParser.swift`.
Supported query tokens: `type:text|image|url`, `app:<bundleid>`, `after:<iso-date>`, quoted phrases, free substring terms, plus the `image:` alias.
`clip-03` now stores URL clips as a distinct kind so `type:url` works on real rows.
README documents the query grammar and the settings/config behavior.
Threat model written at `ours/clip-03/THREAT_MODEL.md`.
Added a parser harness under `ours/clip-03/Tests/QueryParserTests/` covering 13 cases.
Build output app bundle:
`/Users/ashleyraiteri/ashcode/agent-pb/clipboard-lab/ours/clip-03/build/clip-03.app`
Build log:
`reviews/iter-3/clip-03-build.log`
Build status: pass after fixing the copied script execute bit and two Swift 6 actor/concurrency issues.
Raw `swift test` is blocked in this sandbox by SwiftPM's internal sandbox step.
Validation passed with `swift test --disable-sandbox` after replacing unavailable `XCTest`/`Testing` imports with a framework-free harness.
Self-review written to `reviews/iter-3/self-review.md`.
Simplify pass written to `reviews/iter-3/simplify-log.md` and followed by a successful rebuild.
Team review written to `reviews/iter-3/team-review.md` with security, UX, performance, and power-user perspectives comparing against Maccy, Raycast, Alfred, and Clipy.
Source size: 2,071 LOC across package, app sources, and parser harness.
Main remaining risks: plaintext-at-rest storage, intentionally narrow settings scope, heuristic URL detection, and a toolchain image without normal Swift test frameworks.
