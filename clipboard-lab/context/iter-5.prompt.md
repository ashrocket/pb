# Codex dispatch: iter-5 — Paste/Pastebot reviews + build clip-05 (FINAL) + reviews

READ `clipboard-lab/CONTEXT.md`, `clipboard-lab/SPEC.md`,
ALL prior build summaries (`reviews/iter-{1..4}/build-SUMMARY.md`),
`reviews/iter-4/team-review.md`, and skim the clip-04 source tree.

This is the FINAL iteration. clip-05 is the crown jewel — the strongest
entry in the blind review. Spend more time on polish than prior iterations.

## Step 1. Paste + Pastebot reviews (from published sources only)
These are paid apps we cannot install. Write `existing/paste.md` and
`existing/pastebot.md` based on published reviews, official sites, and
press coverage. Same fields as other existing reviews. Be explicit about
what you could and could not verify. Cite every source URL.

- Paste: https://pasteapp.io — visual grid, iCloud sync, pinboards
- Pastebot: https://tapbots.com/pastebot/ — sequential paste, filters,
  custom actions

## Step 2. Build clip-05 — final iteration

New package at `ours/clip-05/`. Carries forward ALL good ideas from
clip-01 through clip-04, plus these new capabilities:

### 2a. Encrypted search (fix plaintext searchable_text gap)
Replace the plaintext `searchable_text` column with an approach that does
not leave cleartext in the DB. Options in priority order:
1. **Encrypted FTS**: tokenize text, HMAC each token with the Keychain key,
   store HMACs in a searchable index. Substring search becomes token-prefix
   match. Document the trade-off (no infix match) in README.
2. **Decrypt-and-scan**: if (1) is too complex, decrypt all rows and
   search in-memory. Document the perf cost in THREAT_MODEL.md.
Pick one, document why.

### 2b. Vision.framework OCR for image clips
When an image clip is captured, run
`VNRecognizeTextRequest` (on-device, no network) to extract text and
store it as searchable metadata. This lets `type:image sometext` find
screenshots containing that text. Handle the async completion properly
on a background queue.

### 2c. Visual polish
The history panel should be the best-looking of all 5 iterations:
- Vibrancy / translucent material background (NSVisualEffectView)
- Image thumbnails in the list (48×48, aspect-fill, rounded corners)
- Clip preview on hover or arrow-key selection (larger preview pane)
- Smooth keyboard navigation with visual selection highlight
- Dark mode support via system appearance

### 2d. Performance
- Lazy-load clips in the history panel (load 20, fetch more on scroll)
- Async image decoding off the main thread
- Debounce search (200ms) so typing doesn't hammer the DB
- Startup: defer non-critical init (OCR queue, settings window) to after
  the menu bar item appears

### 2e. Comprehensive tests
`ours/clip-05/Tests/` with at least 20 test cases covering:
- Encryption round-trip
- HMAC token search (or decrypt-and-scan, whichever you chose)
- Query parser (carry forward all clip-03/04 cases + new ones)
- URL detection edge cases
- OCR mock (feed a known PNG, verify extracted text — you can create a
  tiny test PNG programmatically with CoreGraphics + CoreText)
- Config watcher (write a temp config, verify reload)

Run `swift test --disable-sandbox` and log to
`reviews/iter-5/clip-05-build.log`.

### 2f. Threat model
Most complete of all iterations. Must cover:
- Key management lifecycle
- Encrypted search trade-offs
- OCR data handling (is extracted text encrypted?)
- Memory residency of decrypted clips
- Pasteboard type exclusions
- File permission enforcement
- What is NOT protected and why

### 2g. README
Comprehensive README with: install instructions (unsigned .app caveats),
feature list, query grammar, settings reference, security posture summary,
known limitations.

## Step 3. Self-review, simplify, team review
- `reviews/iter-5/self-review.md` — be ruthless, this is the final entry
- `reviews/iter-5/simplify-log.md` — one pass, but do NOT simplify away
  polish or features. Simplify implementation, not scope.
- `reviews/iter-5/team-review.md` (4 personas, compare against ALL 5
  existing apps: Maccy, Raycast, Alfred, Clipy, Flycut, and insights
  from Paste/Pastebot reviews)

## Step 4. Summary
`reviews/iter-5/build-SUMMARY.md` (≤40 lines for the final iteration):
- Build + test status
- Source LOC + file count
- Feature matrix: clip-05 vs Maccy vs Raycast (the two strongest existing)
- Biggest win, biggest remaining gap
- One-line verdict from each team reviewer
- "Is clip-05 competitive in a blind review?" — honest assessment

## Step 5. Done
Write `DONE` to `reviews/iter-5/iter.done`.

## Discipline
No stdout spam. Don't modify earlier iterations. No branding leakage in
the binary or built strings (this will be anonymized for blind review).
