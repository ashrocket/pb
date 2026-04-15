# Codex dispatch: iter-3 — Clipy review + build clip-03 + reviews

READ `clipboard-lab/CONTEXT.md`, `clipboard-lab/SPEC.md`,
`clipboard-lab/ours/clip-01/DESIGN.md`,
`clipboard-lab/reviews/iter-2/build-SUMMARY.md`,
`clipboard-lab/reviews/iter-2/team-review.md`,
and the clip-02 source tree BEFORE ANY WORK.

## Mandate
1. Add Clipy to the existing-review set (Claude is installing it).
2. Build clip-03 as a NEW SwiftPM package addressing iter-2 weaknesses:
   - **real settings surface** (NSWindow with form controls, not just a
     toml file)
   - **config watcher discipline**: DB writes must NOT trigger reloads.
     Watch only `config.toml`, not the whole directory. If FSEvents is
     directory-scoped, filter by filename in the callback.
   - **search beyond `image:` prefix**: support `app:<bundleid>`,
     `after:<iso-date>`, `type:text|image|url`, plus substring match.
     Document the query grammar in README.
3. Self-review, simplify, team-review, summarize.

## Step 1. Clipy review
Write `existing/clipy.md` with same fields as `existing/maccy.md`. Source
is https://github.com/Clipy/Clipy (Cocoa/Swift, Realm storage). Cite URLs.

## Step 2. Build clip-03
New package at `ours/clip-03/`. Do NOT touch clip-01 or clip-02. Same hard
rules: no Xcode, no SPM deps, LSUIElement, concealed/transient exclusion,
no network, 0600 store at
`~/Library/Application Support/clip-03/history.sqlite`.

Additional files beyond iter-2:
- `Sources/clip-03/SettingsWindow.swift` — real NSWindow with form
  controls (NSTextField + NSButton + NSStepper) bound to the config.
- `Sources/clip-03/QueryParser.swift` — parses the search DSL described
  above into SQL WHERE clauses. Must be testable without a running app.
- Write a small test harness at `ours/clip-03/Tests/QueryParserTests/`
  that runs under `swift test` and covers at least 10 query cases.

Run `scripts/build.sh`. Retry up to 3 times. Log to
`reviews/iter-3/clip-03-build.log`. Also run `swift test` and log result
to the same file.

Write `ours/clip-03/THREAT_MODEL.md`.

## Step 3. Self-review, simplify, team review
- `reviews/iter-3/self-review.md`
- `reviews/iter-3/simplify-log.md` (one pass, rebuild)
- `reviews/iter-3/team-review.md` (4 personas, compare against Maccy,
  Raycast, Alfred, Clipy)

## Step 4. Summary
`reviews/iter-3/build-SUMMARY.md` (≤30 lines).

## Step 5. Done
Write `DONE` to `reviews/iter-3/iter.done`.

## Discipline
No stdout spam. Don't modify earlier iterations. No branding leakage.
