# Codex dispatch: iter-1 build clip-01 + self-review + simplify + team-review

READ `clipboard-lab/CONTEXT.md` AND `clipboard-lab/SPEC.md` AND
`clipboard-lab/ours/clip-01/DESIGN.md` BEFORE ANY WORK.

## Constraints (read carefully)
- No Xcode. Use `swift build` via SwiftPM only.
- Menu bar app (NSStatusItem). `LSUIElement = true` in Info.plist.
- Raw `sqlite3` C API via `import SQLite3`. No SPM dependencies.
- Global hotkey via Carbon `RegisterEventHotKey` OR
  `NSEvent.addGlobalMonitorForEvents` — your call, document why.
- Storage: `~/Library/Application Support/clip-01/history.sqlite` at runtime;
  DO NOT touch that path from your sandbox. Only write code that would write
  there when the app runs.
- Exclude pasteboard types `org.nspasteboard.ConcealedType` and
  `org.nspasteboard.TransientType`.
- Never network. No update checks. No telemetry.

## Step 1. Build
Create a SwiftPM package rooted at `ours/clip-01/`:
    ours/clip-01/
      Package.swift
      Sources/clip-01/
        main.swift
        ClipboardPoller.swift
        Store.swift
        HotkeyManager.swift
        HistoryWindow.swift  (simple NSPanel with a table view + search)
        MenuBar.swift
      bundle/Info.plist
      scripts/build.sh     (builds swift package AND wraps into clip-01.app)
      README.md
      THREAT_MODEL.md

`scripts/build.sh` must, when run from `ours/clip-01/`:
1. `swift build -c release`
2. Create `build/clip-01.app/Contents/{MacOS,Resources}`
3. Copy `.build/release/clip-01` into `Contents/MacOS/`
4. Copy `bundle/Info.plist` into `Contents/`
5. Print path to the produced .app

Run `scripts/build.sh` and capture output to
`reviews/iter-1/clip-01-build.log`. If the build fails, fix the code and
retry up to 3 times. If it still fails, document the failure precisely in
`reviews/iter-1/clip-01-build.log` and continue to step 2 with the
partially working source.

## Step 2. Threat model
Write `ours/clip-01/THREAT_MODEL.md` listing:
- Assets (what's valuable)
- Adversaries (who we defend against)
- What we enforce (concealed exclusion, file perms, no network, etc.)
- What we DO NOT enforce and why (encryption at rest? concurrent writes?
  malicious local processes? etc.)

## Step 3. Self-review (you review your own code)
Write `reviews/iter-1/self-review.md` listing:
- Bugs you can see in your own code
- Missing features from DESIGN.md
- Security holes
- Performance concerns
- What you'd change with more time
Be honest, don't defend decisions — attack them.

## Step 4. Simplify
Based on the self-review, make one simplification pass over the clip-01
source. Goal: cut complexity without losing core value. Rebuild. Log what
you removed and why to `reviews/iter-1/simplify-log.md`. If the rebuild
fails, revert the simplification.

## Step 5. Team review (four personas)
Write `reviews/iter-1/team-review.md` with four clearly labeled sections:
- **Security reviewer**: hunts for storage leaks, privilege boundaries,
  secret exposure, injection vectors
- **UX reviewer**: hotkey ergonomics, result latency, search feel,
  discoverability, first-run experience
- **Performance reviewer**: polling cost, DB growth, memory, startup time,
  search speed at 200 entries
- **Power user reviewer**: wants snippets, regex search, pinning,
  multi-clipboard — what's missing for daily use, what's extraneous

Each persona: 4-8 bullets, specific and actionable.

## Step 6. Summary
Write `reviews/iter-1/build-SUMMARY.md` (≤30 lines):
- Did the build succeed? final binary path?
- Size of source (LOC, files)
- Biggest win of clip-01
- Biggest weakness of clip-01
- Simplification impact
- One-line verdict from each team reviewer
- What iter 2 should change

## Step 7. Done
Write literal `DONE` to `reviews/iter-1/build.done`.

## Discipline
- No stdout spam. Write to files.
- Do NOT modify iter-1 existing reviews or CONTEXT.md or SPEC.md.
- Do NOT reveal in any file that clip-01 is "ours" vs "existing" — the
  blind review depends on this. Internal notes referencing "our build" are
  fine; do not use branding like "clipboard-lab" inside the source or
  built binary strings.
