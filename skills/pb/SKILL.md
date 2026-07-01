---
name: pb
description: Use when the user types /pb or $pb, or asks to copy something from the conversation to the clipboard or paste buffer — "copy that", "copy the query", "grab that command", "put it in my paste buffer", "gimme that". Copies the selected artifact to the system clipboard; with no target given, picks the most recent useful artifact.
---

Copy the artifact to clipboard. Be fast — no explanation, no preamble.

## Select

With args, interpret them freely: artifact type ("command"), description
("the AQL query"), ordinal ("2" = 2nd most recent), or fuzzy intent
("that thing for prod"). Prefer the most recent match.

Without args, pick the most recent useful artifact:
query > shell command > code block > URL > config > plain text.

Ordered sequences: copy first-to-run, not last.

If nothing plausibly matches, say so — don't guess, don't copy noise.

## Copy

```bash
if command -v pbcopy &>/dev/null; then CB="pbcopy"
elif command -v wl-copy &>/dev/null; then CB="wl-copy"
elif command -v xclip &>/dev/null; then CB="xclip -selection clipboard"
elif command -v clip.exe &>/dev/null; then CB="clip.exe"; fi
```

Single-line: `printf '%s' 'CONTENT' | $CB` (escape `'` as `'\''`)

Multi-line: heredoc with `$CB <<'PBEOF'`

No clipboard binary (e.g. SSH session)? Try OSC52 — the terminal sets the
local clipboard:

```bash
printf '\033]52;c;%s\a' "$(printf '%s' "$CONTENT" | base64 | tr -d '\n')" > /dev/tty
```

If that fails too, print the artifact in a fenced code block and tell the
user to copy it manually.

## Rules

- Strip markdown fences and trailing newlines, copy raw content only
- Preserve internal newlines/indentation
- Never copy secrets without explicit request
- One-line confirmation only: `Copied to clipboard: <description>`
