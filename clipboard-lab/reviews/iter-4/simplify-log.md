# Simplify Log

## Pass Goal
Trim leftover state from the iter-4 rescheduling work without changing runtime
behavior.

## Simplification Applied
- Removed the unused `currentPollingInterval` property from
  `ClipboardPoller.swift`.
- Kept timer rescheduling behavior driven directly from
  `normalizedPollingInterval()` so the poller no longer tracks redundant
  interval state.

## Why This Was Worth It
- The poller now has fewer moving pieces after the configuration-driven timer
  refactor.
- There is less stale state to mentally reconcile when reviewing pause/resume
  and interval changes.

## Rebuild
- `./scripts/build.sh`: pass
- `swift test --disable-sandbox` with local cache overrides: pass
- Log: `reviews/iter-4/clip-04-build.log`
