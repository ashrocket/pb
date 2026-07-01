## /pb — Paste Buffer

When the user says "/pb", "$pb", "copy that", "gimme that", "put it in my
paste buffer", or asks to copy something from the conversation, copy it to
their clipboard.

### Select

With args, interpret them freely: artifact type ("command"), description
("the AQL query"), ordinal ("2" = 2nd most recent), or fuzzy intent.
Prefer the most recent match. Without args, pick the most recent useful
artifact: query > shell command > code block > URL > config > plain text.

Ordered sequences: copy first-to-run, not last. If nothing plausibly
matches, say so — don't guess.

### Copy

Detect platform: `pbcopy` (macOS), `wl-copy` / `xclip -selection clipboard`
(Linux), `clip.exe` (WSL). Assign to `$CB`. Single-line:
`printf '%s' 'CONTENT' | $CB`. Escape `'` as `'\''`. Multi-line: heredoc
with `$CB <<'PBEOF'`. No binary? Try OSC52:
`printf '\033]52;c;%s\a' "$(printf '%s' "$CONTENT" | base64 | tr -d '\n')" > /dev/tty`.

### Rules

- Strip markdown fences and trailing newlines, copy raw content only
- Preserve internal newlines/indentation
- Never copy secrets without explicit request
- If no clipboard route works, print artifact in a fenced code block for manual copy
- One-line confirmation: `Copied to clipboard: <description>`
