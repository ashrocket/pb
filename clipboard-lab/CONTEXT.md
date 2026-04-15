# CONTEXT for codex dispatches — READ FIRST

You are working inside `clipboard-lab/` within the `agent-pb` repo. Claude
(the coordinator) is delegating to you to save its context budget. Follow
these rules on every dispatch:

## Output discipline
- Write all artifacts to files. Do NOT print long output to stdout.
- End every task by writing a SUMMARY.md (≤30 lines) covering: what you
  did, what works, what broke, what's next. Claude reads only this.
- Mark task completion by writing the literal string `DONE` to a file whose
  path Claude gives you in the dispatch prompt.

## Working rules
- Read SPEC.md before doing anything design-related.
- Prefer Swift Package Manager. No Xcode is installed.
- Build AppKit apps as unsigned `.app` bundles by hand:
      Contents/MacOS/<binary>
      Contents/Info.plist
      Contents/Resources/
- Our clipboard managers live at `clipboard-lab/ours/clip-0N/`.
- Each build must include: pasteboard polling, persistent store, global
  hotkey, search UI, image support, a written threat model.

## Security baseline (applies to all our builds)
- Store at `~/Library/Application Support/clip-0N/history.sqlite` with
  0600 permissions. Never world-readable.
- Exclude passwords: skip pasteboard items with type
  `org.nspasteboard.ConcealedType` or `org.nspasteboard.TransientType`.
- Do not log clip contents to stdout or files outside the store.
- Never network. No telemetry. No update checks.
- Document what you did and did not enforce in `THREAT_MODEL.md`.

## Division of labor with Claude
Claude (orchestrator) handles anything that must escape the workspace
sandbox: `brew install`, chmod on `/Applications`, launching apps for
runtime tests, anything in `~/Library` outside `Application Support/clip-*`.
If a task needs one of those, write it to `reviews/iter-N/CLAUDE_TODO.md`
and proceed with what you can. Claude will pick it up at the checkpoint.

## Do not
- Do not read or modify files outside `clipboard-lab/`.
- Do not attempt `brew install` — it will fail in your sandbox. Defer to
  Claude via `CLAUDE_TODO.md`.
- Do not grant macOS permissions — tell the user what they need to click.
- Do not rename or delete other iterations' work.
- Do not reveal in any file whether an app is "ours" vs "existing" beyond
  what's already in SPEC.md — the blind review depends on anonymization.
