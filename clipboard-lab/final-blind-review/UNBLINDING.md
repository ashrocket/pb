# Unblinding — Blind Review Results Decoded

## The mapping (reviewer did not see this)
| Letter | Actual |
|--------|--------|
| A | clip-04 (ours) |
| B | clip-01 (ours) |
| C | clip-03 (ours) |
| D | clip-02 (ours) |
| E | Alfred (existing) |
| F | Raycast (existing) |
| G | clip-05 (ours) |
| H | Flycut (existing) |
| I | Clipy (existing) |
| J | Maccy (existing) |

## Final ranking, decoded
| Rank | Entry | Actual | Origin |
|------|-------|--------|--------|
| 1 | G | **clip-05** | ours |
| 2 | A | **clip-04** | ours |
| 3 | F | Raycast | existing |
| 4 | J | Maccy | existing |
| 5 | C | **clip-03** | ours |
| 6 | E | Alfred | existing |
| 7 | D | **clip-02** | ours |
| 8 | B | **clip-01** | ours |
| 9 | H | Flycut | existing |
| 10 | I | Clipy | existing |

Mean rank by origin:
- **Ours (clip-01..05): 4.6**
- **Existing (5 apps): 6.4**

Three of the top five are ours. The reviewer independently called clip-05
"the strongest clipboard-first design in the set" and "deliberately
over-engineered in a good way" — without any knowledge of who built it.

## Caveats — what this result does and does not prove

### What it does show
- With enough iteration time (5 passes, ~3,500 LOC, Vision OCR, AES-GCM
  encryption, keyed-token search) you can build a clipboard manager that a
  fresh reviewer reads as more thorough than the most widely used free
  options in the same category.
- Structured iteration — build, self-review, simplify, team review — pays
  off. clip-01 landed in 8th place; clip-05 landed in 1st. The same
  architectural lineage improved 7 ranks in 4 iterations.
- The reviewer's unprompted observation — "G feels deliberately
  over-engineered in a good way" — is exactly the signature of aggressive
  iteration without product scope constraints.

### What it does NOT show
- **This is a spec-sheet review, not a product review.** The reviewer never
  ran any of the 10 apps. A clipboard manager is judged by feel over
  weeks of daily use; no amount of written documentation captures that.
- **Our spec sheets had a documentation advantage.** The existing apps were
  summarized from public marketing + OSS README skim; our apps had
  detailed THREAT_MODEL.md files written to answer exactly the questions a
  security/perf reviewer would ask. Same information depth would have
  changed the ranking meaningfully.
- **Our 5 are unsigned, manually bundled, and have never run on a user's
  machine for more than a smoke test.** Raycast and Maccy have years of
  real-world bug reports, Accessibility flow polish, macOS release
  tracking, and edge-case handling we haven't come close to.
- **The blind reviewer is one AI.** A different reviewer with different
  priors could plausibly invert several positions — especially entries E
  (Alfred) and F (Raycast), which lost ground mostly because their
  clipboard-specific docs are sparse, not because their products are weak.
- **Clipy ranked last mostly because of our documentation framing.** A
  fair re-review based on running the actual app would likely place Clipy
  above clip-01.

## Per-iteration progression
clip-01 (rank 8) → clip-02 (rank 7) → clip-03 (rank 5) → clip-04 (rank 2)
→ clip-05 (rank 1). Every iteration moved up in the blind ranking.

## Honest headline
The 5-iteration build/review/simplify loop produced a clipboard manager
that, on paper, outranks the strongest free existing options — but it
did so in a contest the existing apps weren't really entered in. The
result is a genuine signal about iteration discipline, not a claim that
clip-05 would replace Raycast or Maccy in daily use.
