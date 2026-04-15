# clipboard-lab — 5 iterations, 10 reviewed

## Goal
Comparative experiment: build 5 macOS clipboard history managers, test them
alongside 5 real existing apps, iterate via review/simplify/team-review, then
subject all 10 to a blind final review by a fresh agent with no memory of
which 5 were built in this experiment.

## Layout
    clipboard-lab/
      SPEC.md                   # this file
      CONTEXT.md                # context every codex dispatch reads first
      existing/                 # notes + test logs on real apps
        raycast.md
        maccy.md
        alfred.md
        clipy.md
        flycut.md
        paste.md (reviews only, paid)
        pastebot.md (reviews only, paid)
      ours/
        clip-01/                # swift package, bundled .app, notes.md, REVIEW.md
        clip-02/
        clip-03/
        clip-04/
        clip-05/
      reviews/
        iter-1/                 # per-iteration artifacts
          existing-review.md
          build-log.md
          self-review.md
          simplify-log.md
          team-review.md        # security / ux / perf / power-user reviewers
        iter-2/ ... iter-5/
      final-blind-review/
        entries/                # 10 anonymized dirs: entry-A .. entry-J
          manifest.json         # our record of which entry = which app
        blind-review.md         # codex output, no origin context

## Language for our builds
Swift 6.2 via `swift package` (no Xcode). Minimal AppKit menu bar app built as
an unsigned `.app` bundle. SQLite via GRDB or raw sqlite3 C API. Global hotkey
via Carbon `RegisterEventHotKey` or MASShortcut-equivalent.

Rationale: native performance, closest to what existing apps ship, low UI
overhead, testable from CLI (pbcopy + sqlite3 query against store file).

## Iteration protocol
Each iteration N does, in order:
1. **existing-review**: pick new existing app(s) to add to the comparison set,
   install + test (or read reviews for paid), log features/perf/security.
2. **build**: codex dispatch produces ours/clip-0N/ — working .app, README,
   feature list, self-described threat model.
3. **self-review**: codex reviews clip-0N against the spec, produces review.md
   listing bugs, missing features, security holes, perf concerns.
4. **simplify**: codex rewrites clip-0N to cut complexity without losing core
   value. Logs what was removed and why.
5. **team-review**: four codex personas (security, UX, performance, power
   user) each write a short review of clip-0N + the comparison set.

Checkpoint: Claude reads only the iteration's SUMMARY.md (≤30 lines written
by codex) and decides whether to continue.

## Existing apps added per iteration
- Iter 1: Maccy, Raycast
- Iter 2: + Alfred (base, no clipboard via Powerpack — document the gap)
- Iter 3: + Clipy
- Iter 4: + Flycut
- Iter 5: + Paste (review-only) and Pastebot (review-only)

Final set: 5 free apps actually tested + 2 paid apps reviewed from published
reviews + 5 of ours. For the blind review we need exactly 10 entries, so we
use: Raycast, Maccy, Alfred, Clipy, Flycut + clip-01..clip-05. Paste and
Pastebot inform the design but do not enter the blind ranking.

## Codex dispatch pattern
Every call:
    cd clipboard-lab
    codex exec --skip-git-repo-check --full-auto \
      "Read CONTEXT.md first. Then: <task>. Write results to <file>.
       Do not print long output to stdout — only a 5-line summary.
       Mark completion by writing DONE to <file>.done"
Claude polls for the .done file or waits for exit code, then reads only
the summary file (not full artifacts).

## Blind final review
Entries are symlinked / copied into `final-blind-review/entries/entry-{A..J}/`
with randomized letter assignment and stripped READMEs (no "clip-0N" or
vendor branding inside the anonymized tree — we rename binaries, strip about
strings where feasible). The codex subagent is told: "Ten clipboard managers
live in entries/. Rank them on correctness, speed, security, UX, feature
completeness. You have no prior knowledge of their origin."

Claude holds the manifest and does the unblinding writeup after codex
returns its ranking.

## Token budget
Claude: orchestrator only. Reads SUMMARY.md files, writes spec + final
writeup. Target: <100k tokens on the Claude side across the whole experiment.

Codex: does all installs, Swift writing, testing, reviewing. Its token cost
is its own budget.
