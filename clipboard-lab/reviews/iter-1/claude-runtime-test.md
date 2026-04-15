# clip-01 Claude-side runtime smoke test

Run by Claude (orchestrator) — outside the codex sandbox. Codex cannot write
to `~/Library` so it cannot test the runtime; this is the gap-filler.

## Procedure
1. `find` the bundle structure of `build/clip-01.app`.
2. Launch `Contents/MacOS/clip-01` directly (skips Gatekeeper for testing).
3. Wait 3 seconds, verify the process is alive with `kill -0`.
4. Kill the process.
5. Inspect `~/Library/Application Support/clip-01/`.

## Result
- Process launched cleanly. PID alive after 3s. Exited cleanly on TERM.
- No stdout/stderr output (good — no log noise).
- `~/Library/Application Support/clip-01/` created with mode `0700`.
- `history.sqlite` created with mode `0600`.
- `history` table initialized on first launch.

## Verdict
Build is real and runs. Storage permissions match the threat model.
Hotkey + UI not exercised here — would need Accessibility permission grant
and a real interactive session.

## Outstanding
- User has not granted Accessibility/Input Monitoring to clip-01. Without
  it, the global hotkey will not fire and the app cannot read clipboard
  beyond what NSPasteboard provides without elevated perms.
- App is unsigned. Launching via Finder will trigger Gatekeeper.
