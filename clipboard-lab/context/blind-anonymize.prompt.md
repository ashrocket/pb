# Codex dispatch: build anonymized entries for blind review

READ `clipboard-lab/CONTEXT.md` AND `clipboard-lab/SPEC.md` first.

## Mandate
Build `final-blind-review/entries/entry-{A..J}/` — ten normalized spec
sheets, randomized letter-to-app mapping, with ZERO origin leakage.

## Inputs
Existing app reviews: `existing/maccy.md`, `existing/raycast.md`,
`existing/alfred.md`, `existing/clipy.md`, `existing/flycut.md`.

Our 5 builds: `ours/clip-01/` through `ours/clip-05/`. For each, use
THREAT_MODEL.md + README.md + DESIGN.md (if present) + the build-SUMMARY
from `reviews/iter-N/` as source material.

NOTE: Paste and Pastebot are review-only; they do NOT enter the blind
ranking per SPEC.md. Do not create entries for them.

## Output format — identical for all 10 entries
Each `final-blind-review/entries/entry-X/` directory contains exactly
these files, and nothing else:

- `summary.md` — one-paragraph description of the app and its design
  philosophy (100-150 words)
- `features.md` — bullet list: history depth, search, image support,
  pinning, snippets, sync, hotkey, settings UI, OCR, query syntax
- `security.md` — bullets: concealed/transient handling, storage encryption,
  key management, password-manager exclusions, network behavior, process
  isolation, threat model completeness
- `storage.md` — bullets: storage path, format, file permissions, size
  caps, retention policy
- `performance.md` — bullets: polling interval, search speed claim, memory
  footprint, startup cost, known hot paths
- `ux.md` — bullets: hotkey ergonomics, keyboard navigation, visual
  polish, first-run experience, settings discoverability, dark mode

Each file: concise, factual, fair. If a claim is unverifiable, say "not
documented" or "unknown" — do NOT guess.

## Anti-leakage rules (CRITICAL)
- No mention of "clip-01" / "clip-0N" / "ours" / "clipboard-lab" / "iter-N"
  anywhere in entry files.
- No mention of specific product names: strip "Maccy", "Raycast", "Alfred",
  "Clipy", "Flycut", "clip-0N". Use neutral paraphrasing.
- No SwiftPM / "built with no Xcode" / unsigned-bundle tells (those
  correlate with ours). If a spec sheet must mention build tooling, say
  "native macOS application" uniformly for all 10.
- No source links, no GitHub URLs, no version strings.
- File creation timestamps will still leak ordering — fix by touching all
  entry files to the same timestamp at the end:
      find final-blind-review/entries -type f -exec touch -t 202604120000 {} +
- The 5 open-source apps have public source; the 5 ours have source in
  this repo. Do NOT reference source availability in entries. The blind
  reviewer gets ONLY the spec sheets — not the code.

## Randomization
1. Build a mapping of 10 apps → letters A..J using a pseudo-random
   shuffle seeded from the current time. Write it to
   `final-blind-review/manifest.json` as
   `{"A": "<real name>", "B": ..., ...}`.
2. The manifest is PRIVATE — the blind reviewer must not see it. Put a
   `.reviewer-ignore` file in `final-blind-review/` listing `manifest.json`
   as ignored. (This is just a signal; the real protection is Claude
   running the blind reviewer with `-C final-blind-review/entries`.)

## Reviewer README
Write `final-blind-review/entries/README.md` — the ONLY context the blind
reviewer gets. Text:

    # Blind Clipboard Manager Review

    Ten macOS clipboard history managers are summarized in entry-A through
    entry-J. Each entry has the same six files: summary, features,
    security, storage, performance, ux.

    You have no prior knowledge of these products. Review objectively.

    Produce a ranking based on: correctness (does it do what a clipboard
    manager needs?), security posture, feature completeness, performance
    claims, and UX polish. Output a single `ranking.md` at this directory
    with:
      1. A ranked list (1-best to 10-worst) with letter + one-line verdict
      2. A per-entry one-paragraph writeup
      3. A final section: "which entries feel like the strongest
         and weakest, and why?"

    Do not try to identify the products by name. Rank based purely on the
    spec sheets.

## Step done
Write `DONE` to `final-blind-review/anonymize.done` when entries/ is
complete, manifest is written, and timestamps are normalized.
Write a terse `final-blind-review/ANONYMIZE_SUMMARY.md` (≤15 lines)
listing the randomized mapping (for Claude's records only) and any
anti-leak concerns.

## Discipline
No stdout spam. Never print the manifest mapping to stdout — only write
to files.
