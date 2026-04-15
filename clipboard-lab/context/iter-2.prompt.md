# Codex dispatch: iter-2 — Alfred review + build clip-02 + reviews

READ `clipboard-lab/CONTEXT.md`, `clipboard-lab/SPEC.md`,
`clipboard-lab/ours/clip-01/DESIGN.md`, `clipboard-lab/reviews/iter-1/build-SUMMARY.md`,
and `clipboard-lab/reviews/iter-1/team-review.md` BEFORE ANY WORK.

## Iteration 2 mandate
1. Add Alfred to the existing-review set (Claude is installing it).
2. Build clip-02 — a fresh sibling of clip-01 that addresses iter-1 team
   review weaknesses, NOT a refactor of clip-01. Both must remain runnable.
3. Self-review, simplify, team-review clip-02.

## Step 1. Alfred existing review
Write `existing/alfred.md` covering the same fields as `existing/maccy.md`.
Be explicit about the clipboard-history-requires-Powerpack gap. Note that
free-tier Alfred does NOT include clipboard history. Source citations
required.

Do NOT brew install anything. Claude is handling installs.

## Step 2. Build clip-02 (separate package, not a refactor)
Create `ours/clip-02/` as a NEW SwiftPM package, structurally similar to
clip-01 but with these improvements driven by iter-1 team review:
- **Keyboard controls**: explicit arrow + enter + escape + cmd-number quick
  picks in the history panel; documented in README.
- **Image handling**: store images as PNG (not TIFF) with width/height/byte
  metadata in the row; allow filtering by `image:` prefix in search.
- **Privacy controls**: settings file at
  `~/Library/Application Support/clip-02/config.toml` with:
    - per-app exclusion list (bundle IDs)
    - max-bytes-per-clip cap (default 1MB)
    - "pause capture" toggle
  Apply on launch and on-the-fly when the file changes (FSEvents).
- **Storage path**: `~/Library/Application Support/clip-02/history.sqlite`
  with same 0600 perms as clip-01.

Same hard rules: no Xcode, no SPM dependencies, raw `import SQLite3`,
LSUIElement, exclude concealed/transient pasteboard types, no network.

`scripts/build.sh` follows the same pattern as clip-01 — produces
`build/clip-02.app` with `Contents/MacOS/clip-02` + `Contents/Info.plist`.

If the build fails, retry up to 3 times then continue with the source
state. Log to `reviews/iter-2/clip-02-build.log`.

Write `ours/clip-02/THREAT_MODEL.md` listing what's enforced and what isn't.

## Step 3. Self-review, simplify, team review
Same structure as iter-1:
- `reviews/iter-2/self-review.md`
- `reviews/iter-2/simplify-log.md` (one simplification pass, rebuild)
- `reviews/iter-2/team-review.md` (4 personas: security, UX, perf, power user)

The team review must compare clip-02 against the existing set so far
(Maccy, Raycast, Alfred). One paragraph per persona on how clip-02 stacks
up against the strongest existing app in their domain.

## Step 4. Summary
Write `reviews/iter-2/build-SUMMARY.md` (≤30 lines):
- Build status, final binary path, source LOC
- What clip-02 added vs clip-01 in concrete terms
- One-line verdict per team reviewer
- One-line comparison: "vs Maccy, clip-02 is..."
- What iter 3 should change

## Step 5. Done
Write literal `DONE` to `reviews/iter-2/iter.done`.

## Discipline
- No stdout spam.
- Do NOT modify clip-01 files. clip-02 is a new sibling package.
- Anonymization: no "ours" / "clip-lab" branding inside the binary or
  built strings.
