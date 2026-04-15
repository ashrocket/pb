# Simplify Log

## What I Removed
- I removed the unused config-stream teardown helper that only existed because
  of an earlier deinit path and was no longer reachable after the Swift 6
  actor-isolation fixes.
- I removed the more brittle FSEvents path-suffix filtering logic and replaced
  it with a single reload call whenever the watched support directory reports a
  change.

## Why
- The dead teardown method added complexity without any user-visible value in a
  process-lifetime controller.
- The old path matching tried to be selective, but it was easy to make wrong
  for atomic save patterns. Reloading the small TOML file directly is simpler
  and avoids edge cases where config edits would be missed.

## Outcome
- The simplified source rebuilt successfully.
- The core iter-2 value stayed intact: watched config file, PNG image storage,
  metadata-aware image search, and explicit keyboard controls all remain.
- The main tradeoff is that config reloads can now happen more often than
  strictly necessary because any support-directory change triggers a cheap
  re-read.
