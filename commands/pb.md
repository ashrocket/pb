---
description: Copy an artifact from this conversation to the clipboard — /pb picks the most recent useful thing, /pb <hint> picks the best match
argument-hint: [what to copy — a type, description, or ordinal]
---

Copy an artifact from this conversation to the user's clipboard.

What the user asked for: $ARGUMENTS

Invoke the `pb:pb` skill with the request above as its arguments. If the
request is empty, invoke it with no arguments — the skill picks the most
recent useful artifact.

If the skill is unavailable, do it directly: choose the artifact (with a
hint, interpret it — type, description, or ordinal; without one, most
recent useful: query > shell command > code block > URL > config > plain
text), pipe the raw content to pbcopy / wl-copy / xclip -selection
clipboard / clip.exe, and confirm in one line. Never copy secrets unasked.
